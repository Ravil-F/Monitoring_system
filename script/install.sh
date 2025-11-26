#!/bin/bash

# Скрипт установки и настройки системы мониторинга веб-приложения на C

# Подключаем доп. функции

set -e  # Завершать выполнение при любой ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Установка зависимостей
install_dependencies() {
    print_info "Installing dependencies..."
    
    # Обновляем пакеты
    apt-get update
    
    # Устанавливаем необходимые пакеты
    apt-get install -y gcc make curl build-essential
}

# Компиляция приложения
compile_application() {
    print_info "Compiling C application..."
    
    # Переходим в директорию с приложением
    cd app
    
    # Компилируем приложение
    if make; then
        print_info "Application compiled successfully"
    else
        print_error "Failed to compile application"
        exit 1
    fi
    
    # Возвращаемся обратно
    cd ..
}

# Создание структуры директорий
create_directories() {
    print_info "Creating directory structure..."
    
    mkdir -p /opt/monitoring-system/app
    mkdir -p /opt/monitoring-system/scripts
    mkdir -p /etc/monitoring-system
    mkdir -p /var/log/monitoring-system
    
    # Создаем файлы логов
    touch /var/log/simple_app.log
    touch /var/log/app_monitor.log
    chmod 644 /var/log/simple_app.log
    chmod 644 /var/log/app_monitor.log
}

# Копирование файлов
copy_files() {
    print_info "Copying application and configuration files..."
    
    # Копируем скомпилированное приложение
    cp app/simple_app /usr/local/bin/
    chmod +x /usr/local/bin/simple_app
    
    # Копируем исходный код (для возможной перекомпиляции)
    cp app/simple_app.c /opt/monitoring-system/app/
    cp app/Makefile /opt/monitoring-system/app/
    
    # Копируем скрипт мониторинга
    cp scripts/monitor.sh /opt/monitoring-system/scripts/
    chmod +x /opt/monitoring-system/scripts/monitor.sh
    
    # Копируем конфигурацию
    cp config/monitoring.conf /etc/monitoring-system/
}

# Настройка systemd сервиса для приложения
setup_app_service() {
    print_info "Setting up application systemd service..."
    
    cat > /etc/systemd/system/simple-app.service << EOF
[Unit]
Description=Simple Hello World Web Application (C)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/simple_app
Restart=on-failure
RestartSec=5
StandardOutput=append:/var/log/simple_app.log
StandardError=append:/var/log/simple_app.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable simple-app.service
    systemctl start simple-app.service
}

# Настройка cron для мониторинга
setup_monitoring_cron() {
    print_info "Setting up monitoring cron job..."
    
    # Загружаем интервал из конфигурации
    source /etc/monitoring-system/monitoring.conf
    
    # Добавляем задание в crontab
    (crontab -l 2>/dev/null | grep -v "/opt/monitoring-system/scripts/monitor.sh"; \
     echo "*/$CHECK_INTERVAL * * * * /opt/monitoring-system/scripts/monitor.sh") | crontab -
    
    print_info "Cron job configured to run every $CHECK_INTERVAL seconds"
}

# Настройка logrotate
setup_logrotate() {
    print_info "Setting up log rotation..."
    
    cat > /etc/logrotate.d/monitoring-system << EOF
/var/log/simple_app.log /var/log/app_monitor.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF
}

# Запуск начальной проверки
initial_check() {
    print_info "Performing initial application check..."
    
    # Даем приложению время на запуск
    sleep 3
    
    # Проверяем, что приложение запустилось
    if systemctl is-active --quiet simple-app.service; then
        print_info "Application started successfully"
    else
        print_error "Failed to start application"
        systemctl status simple-app.service
        exit 1
    fi
    
    # Проверяем доступность приложения
    if curl -s http://localhost:8080/ > /dev/null; then
        print_info "Application is responding correctly"
    else
        print_error "Application is not responding"
        exit 1
    fi
    
    # Проверяем health endpoint
    if curl -s http://localhost:8080/health | grep -q "healthy"; then
        print_info "Health check endpoint is working"
    else
        print_error "Health check endpoint is not working"
        exit 1
    fi
}

# Основная функция установки
main_install() {
    print_info "Starting monitoring system installation..."
    
    check_root
    install_dependencies
    compile_application
    create_directories
    copy_files
    setup_app_service
    setup_monitoring_cron
    setup_logrotate
    initial_check
    
    print_info "Installation completed successfully!"
    print_info "Application URL: http://localhost:8080"
    print_info "Health check: http://localhost:8080/health"
    print_info "Monitor log: /var/log/app_monitor.log"
    print_info "Application log: /var/log/simple_app.log"
    print_info "Service control: systemctl status simple-app.service"
}

# Функция обновления
update_system() {
    print_info "Updating monitoring system..."
    
    check_root
    
    # Останавливаем сервис
    systemctl stop simple-app.service
    
    # Перекомпилируем и обновим файлы
    compile_application
    copy_files
    
    # Перезапускаем сервис
    systemctl daemon-reload
    systemctl start simple-app.service
    
    print_info "Update completed successfully!"
}

# Обработка аргументов командной строки
case "$1" in
    "install")
        main_install
        ;;
    "update")
        update_system
        ;;
    *)
        echo "Usage: $0 {install|update}"
        echo "  install - Install the monitoring system"
        echo "  update  - Update the monitoring system"
        exit 1
        ;;
esac