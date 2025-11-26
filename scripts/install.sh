#!/bin/bash

# Скрипт установки и настройки системы мониторинга веб-приложения на C

# Подключаем доп. функции
# Определяем директорию где находится скрипт
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Загружаем вспомогательные функции
if [[ -f "$SCRIPT_DIR/help_func.sh" ]]; then
    . "$SCRIPT_DIR/help_func.sh"
else
    echo "ERROR: help_func.sh not found in $SCRIPT_DIR"
    exit 1
fi

set -e  # Завершать выполнение при любой ошибке



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