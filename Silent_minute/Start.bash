#!/bin/bash
set -u
# ===== Налаштування =====
#         true|false
checkdate=true          # запуск лише в будні
checkNTPSync=true       # перевіряти синхронізацію часу
StartStopLog=true       # логувати старт/стоп
muteEnd=true            # Після завершення поставити 0% гучності
# Шлях до скрипта
scriptdir="$(cd -- "$(dirname -- "$0")" && pwd)"
logfile="$scriptdir/logfile.log"
# Файли
stuk="metronom.wav"
gimn="gimn.wav"
# Гучність (0-100)
stukVol="100"
gimnVol="60"
# Метод відтворення: 1 - alsa (aplay), 2 - cvlc
metod=1
# Затримка між відтвореннями (в секундах. 0 відсутність затримки)
delayt="0"
# ALSA контрол (якщо потрібно змінити)
mixerCtl="Master"

# ===== Перевірки ====
# NTP
if [ "$checkNTPSync" = true ]; then
    ntpStatus=$(timedatectl show -p NTPSynchronized --value 2>/dev/null || echo "unknown")
    if [ "$ntpStatus" = "no" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - NTP не синхронізовано" | tee -a "$logfile"
        exit 1
    elif [ "$ntpStatus" = "yes" ]; then
        : # ок
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Невідомий статус NTP" | tee -a "$logfile"
        exit 1
    fi
fi
# Лише будні
if [ "$checkdate" = true ]; then
    current_day=$(date +%u)
    if [ "$current_day" -gt 5 ]; then
        echo "Сьогодні вихідні, сповіщення не працює"
        exit 0
    fi
fi
# Існування файлів
if [ ! -f "$scriptdir/$stuk" ] || [ ! -f "$scriptdir/$gimn" ]; then
    echo "Файл або файли для відтворення не знайдено" | tee -a "$logfile"
    exit 1
fi
# Валідація гучності
for v in "$stukVol" "$gimnVol"; do
    case "$v" in
        ''|*[!0-9]*)
            echo "Некоректне значення гучності: $v" | tee -a "$logfile"; exit 1;;
    esac
    if [ "$v" -lt 0 ] || [ "$v" -gt 100 ]; then
        echo "Гучність поза межами 0-100: $v" | tee -a "$logfile"; exit 1
    fi
done
# Перевірка наявності необхідних утиліт для роботи
need_amixer=false
case "$metod" in
  1)
     command -v aplay >/dev/null || { echo "aplay не знайдена. ALSA можливо не встановлена" | tee -a "$logfile"; exit 1; }
     need_amixer=true
     ;;
  2)
     command -v cvlc  >/dev/null || { echo "cvlc не знайдена. Можливо, VLC не встановлено" | tee -a "$logfile"; exit 1; }
     need_amixer=true
     ;;
  *)
     echo "Невірно вказаний метод" | tee -a "$logfile"
     exit 1
     ;;
esac
if $need_amixer; then
    command -v amixer >/dev/null || { echo "amixer не знайдена. Можливо, ALSA не повністю встановлена" | tee -a "$logfile"; exit 1; }
fi

log_start() {
    if [ "$StartStopLog" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Відтворення запущено" | tee -a "$logfile"
    fi
}

log_end() {
    if [ "$StartStopLog" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Відтворення завершено" | tee -a "$logfile"
    fi
}

alsaMetod () {
    log_start
    amixer -q set "$mixerCtl" "${stukVol}%"
    aplay "$scriptdir/$stuk"
    sleep "$delayt"
    amixer -q set "$mixerCtl" "${gimnVol}%"
    aplay "$scriptdir/$gimn"
}

cvlcMetod () {
    log_start
    amixer -q set "$mixerCtl" "${stukVol}%"
    cvlc --no-video --play-and-exit "$scriptdir/$stuk"
    sleep "$delayt"
    amixer -q set "$mixerCtl" "${gimnVol}%"
    cvlc --no-video --play-and-exit "$scriptdir/$gimn"
}

case "$metod" in
  1) alsaMetod ;;
  2) cvlcMetod ;;
esac

log_end

if [ "$muteEnd" = true ]; then
    amixer -q set "$mixerCtl" 0%
    # або: amixer -q set "$mixerCtl" mute
fi
