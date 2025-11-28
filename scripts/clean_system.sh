#!/bin/bash

echo "=== Удаление системы мониторинга ==="

# 1. Останавливаем и удаляем сервис
echo "Останавливаем сервис..."
sudo systemctl stop simple-app.service 2>/dev/null
sudo systemctl disable simple-app.service 2>/dev/null
sudo rm -f /etc/systemd/system/simple-app.service
sudo systemctl daemon-reload

# 2. Удаляем файлы приложения
echo "Удаляем файлы приложения..."
sudo rm -f /usr/local/bin/simple_app
sudo rm -rf /opt/monitoring-system
sudo rm -rf /etc/monitoring-system

# 3. Удаляем логи
echo "Удаляем логи..."
sudo rm -f /var/log/simple_app.log
sudo rm -f /var/log/app_monitor.log

# 4. Чистим cron
echo "Чистим cron задания..."
crontab -l 2>/dev/null | grep -v "monitor.sh" | crontab -

# 5. Убиваем процессы если остались
echo "Проверяем процессы..."
sudo pkill -f simple_app 2>/dev/null || true

echo "=== Готово! Система мониторинга удалена ==="