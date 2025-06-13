#!/bin/bash
# Перевіряти дату перед запуском, для запуску лише в будні дні. true|false
checkdate=true
# Перевірити чи відбулась сихронізація часу з NTP сервером, якщо не выдбулось завершити роботу скрипта. true|false
checkNTPSync=true
# Писати в лог файл про початок та завершення виконання скрипта. true|false
StartStopLog=true
# Домашня директорія скрипта
scriptdir="/home/pi/Desktop/Silent_minute"
# Назви файлів для відтворення. Обовязкого в форматі wav.
stuk="metronom.wav" 
gimn="gimn.wav"
# Рівень гучності для метроному та гімну.
stukVol="100"
gimnVol="60"
# Затримка між відтворенням метроному та гімну в секундах, 0 - відсутність затримки.
delayt="0"
# __________________________________

if ! command -v aplay >/dev/null; then
    echo "aplay не знайдена. ALSA можливо не встановлена" | tee -a "$scriptdir/logfile.log"
    exit 1
fi
if ! command -v amixer >/dev/null; then
    echo "amixer не знайдена. Можливо, ALSA не повністю встановлена" | tee -a "$scriptdir/logfile.log"
    exit 1
fi
if [ "$checkNTPSync" == true ]; then
    ntpStatus=$(timedatectl show -p NTPSynchronized --value)
    if [ "$ntpStatus" == "no" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - NTP не синхронізовано" | tee -a "$scriptdir/logfile.log"
        exit 1
    elif [ "$ntpStatus" == "yes" ]; then
        echo "NTP синхронізовано"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Невідомий статус NTP" | tee -a "$scriptdir/logfile.log"
        exit 1
    fi
fi
if [ "$checkdate" == true ]; then
    # Якщо день - будній (1-5 означає Пн-Пт)
    current_day=$(date +%u)
    if [ "$current_day" -gt 5 ]; then
        echo "Сьогодні вихідні, сповіщення не працює"
        exit 1
    fi
fi
if [ ! -f "$scriptdir/$stuk" ] || [ ! -f "$scriptdir/$gimn" ]; then
    echo "Файл або файли для відтворення не знайдено" | tee -a "$scriptdir/logfile.log"
    exit 1
fi
if [ "$StartStopLog" == true ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Відтворення запущено" | tee -a "$scriptdir/logfile.log"
fi
amixer set Master $stukVol%
aplay $scriptdir/$stuk
sleep $delayt
amixer set Master $gimnVol%
aplay $scriptdir/$gimn
if [ "$StartStopLog" == true ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Відтворення завершено" | tee -a "$scriptdir/logfile.log"
fi