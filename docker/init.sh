#!/bin/bash

# Вывод информации о системе при запуске
echo "================================="
echo "Запуск мини-Linux контейнера"
echo "================================="
echo "Hostname: $(hostname)"
echo "Ядро: $(uname -a)"
echo "Alpine версия: $(cat /etc/alpine-release)"
echo "================================="

# Настройка переменных окружения
export PATH=$PATH:/usr/local/bin
export TERM=xterm
export LANG=ru_RU.UTF-8

# Запуск cron демона
crond

# Запуск Nginx на переднем плане
echo "Запуск Nginx..."
nginx -g "daemon off;"