#!/bin/bash

# Скрипт мониторинга веб-приложения на C
# Проверяет доступность приложения и перезапускает при необходимости

# Загрузка конфигурации
CONFIG_FILE="/etc/monitoring-system/monitoring.conf"

# Лог-файл
LOG_FILE="/var/log/app_monitor.log"

# Функция для логирования
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Проверяем существование конфигурационного файла
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_message "ERROR: Configuration file $CONFIG_FILE not found"
    exit 1
fi

# Загружаем конфигурацию
source "$CONFIG_FILE"

# Функция проверки доступности приложения
check_application() {
    local response
    local status
    
    # Отправляем HTTP-запрос к health endpoint приложения
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://${APP_HOST}:${APP_PORT}${HEALTH_ENDPOINT}" --connect-timeout 10 --max-time 15)
    status=$?
    
    if [[ $status -eq 0 ]] && [[ $response -eq 200 ]]; then
        log_message "INFO: Application is healthy (HTTP $response)"
        return 0
    else
        log_message "ERROR: Application check failed (curl exit: $status, HTTP: $response)"
        return 1
    fi
}

# Функция проверки процесса приложения
check_application_process() {
    if pgrep -f "$APP_NAME" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Функция перезапуска приложения
restart_application() {
    log_message "INFO: Attempting to restart application..."
    
    # Останавливаем текущий процесс приложения
    pkill -f "$APP_NAME" || true
    sleep 2
    
    # Проверяем, что процесс остановился
    if check_application_process; then
        log_message "WARNING: Application process still running, forcing kill"
        pkill -9 -f "$APP_NAME" || true
        sleep 1
    fi
    
    # Запускаем приложение заново
    nohup "$APP_PATH" >> "$APP_LOG_FILE" 2>&1 &
    local app_pid=$!
    
    sleep 3  # Даем приложению время на запуск
    
    # Проверяем, запустился ли процесс
    if check_application_process; then
        log_message "INFO: Application restarted successfully (PID: $(pgrep -f "$APP_NAME"))"
        return 0
    else
        log_message "ERROR: Failed to restart application"
        return 1
    fi
}

# Функция запуска приложения если оно не запущено
start_application_if_needed() {
    if ! check_application_process; then
        log_message "INFO: Application not running, starting..."
        nohup "$APP_PATH" >> "$APP_LOG_FILE" 2>&1 &
        sleep 3
        
        if check_application_process; then
            log_message "INFO: Application started successfully"
        else
            log_message "ERROR: Failed to start application"
            return 1
        fi
    fi
    return 0
}

# Основной цикл мониторинга
main() {
    log_message "INFO: Starting application monitoring cycle"
    
    # Проверяем, нужно ли запустить приложение
    if ! start_application_if_needed; then
        log_message "ERROR: Failed to start application, attempting restart"
        if ! restart_application; then
            log_message "CRITICAL: All restart attempts failed"
            return 1
        fi
    fi
    
    # Проверяем доступность приложения
    if ! check_application; then
        log_message "WARNING: Application is not responding, attempting restart"
        if restart_application; then
            log_message "INFO: Restart completed successfully"
            
            # Даем время на запуск и проверяем снова
            sleep 5
            if check_application; then
                log_message "INFO: Application is now healthy after restart"
            else
                log_message "ERROR: Application still not responding after restart"
            fi
        else
            log_message "ERROR: Restart failed, will retry next cycle"
        fi
    else
        log_message "INFO: Application is running normally"
    fi
    
    log_message "INFO: Monitoring cycle completed"
}

# Запускаем основную функцию
main "$@"