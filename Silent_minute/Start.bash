#!/bin/bash
set -u
# ===== Налаштування =====
#         true|false
checkdate=true          # запуск лише в будні
checkNTPSync=true       # перевіряти синхронізацію часу
StartStopLog=true       # логувати старт/стоп
muteEnd=true            # після завершення поставити 0% гучності
enablePing=false         # вмикати «пінг» (короткий синус) перед основним звуком
pingDur=500    # тривалість у мс
pingFreq=1000  # частота, Гц
# Файли для відтворення (обов’язково WAV для методу ALSA/aplay)
stuk="metronom.wav"
gimn="gimn.wav"
# Гучність (0-100)
stukVol="100"
gimnVol="60"
delayt="0"  # Затримка між відтвореннями (сек). 0 = без паузи.
# Метод відтворення:
#   1 = ALSA (aplay)
#       - дуже легкий і швидкий
#       - підтримує тільки прості формати (WAV/RAW PCM)
#       - підходить коли потрібна мінімальна затримка і стабільність
#   2 = VLC (cvlc)
#       - універсальний плеєр, підтримує багато форматів (WAV, MP3, OGG, FLAC...)
#       - важчий за aplay, але гнучкіший
metod=1

# Номер ALSA-карти:
#   Це карта (аудіопристрій), через яку відтворюється звук.
#   Дізнатися можна командою:
#       aplay -l
#   Приклад виводу на RPi2:
#       card 0: Headphones [bcm2835 Headphones], device 0 ...
#       card 1: vc4hdmi    [vc4-hdmi],           device 0 ...
#   Якщо звук іде з аналогового виходу (навушники) → ставимо 0.
#   Якщо через HDMI → ставимо 1.
amixer_card=0

# ALSA контролер гучності:
#   Це назва елемента мікшера, яким реально керується гучність відтворення.
#   На Raspberry Pi 2 для аналогового виходу (навушники) це зазвичай "PCM".
#   Для HDMI може бути "Digital" або "HDMI".
#   Перевірити список можна командами:
#       aplay -l                   # Для відображення списку карт
#      amixer -c 0 scontrols      # Для карти 0 (приклад)
#         Simple mixer control 'PCM',0   
#      amixer -c 1 scontrols      # Для карти 1
mixerCtl="PCM"

# Шлях до скрипта / лог
scriptdir="$(cd -- "$(dirname -- "$0")" && pwd)"
logfile="$scriptdir/logfile.log"




# ============================ #
# ======== ТІЛО СКРИПТА ====== #
# ============================ #

# ===== Логування запуску\завершення у файл =====
if [ "$StartStopLog" = true ]; then
  exec > >(tee -a "$logfile") 2>&1
fi

# ===== Перевірки =====
# NTP
if [ "$checkNTPSync" = true ]; then
  ntpStatus=$(timedatectl show -p NTPSynchronized --value 2>/dev/null || echo "unknown")
  if [ "$ntpStatus" = "no" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - NTP не синхронізовано"
    exit 1
  elif [ "$ntpStatus" != "yes" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Невідомий статус NTP: $ntpStatus"
    exit 1
  fi
fi
# Будні дні (1..5)
if [ "$checkdate" = true ]; then
  current_day=$(date +%u)
  if [ "$current_day" -gt 5 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Сьогодні вихідні, сповіщення не працює"
    exit 0
  fi
fi
# Наявність файлів
if [ ! -f "$scriptdir/$stuk" ] || [ ! -f "$scriptdir/$gimn" ]; then
  echo "Файл або файли для відтворення не знайдено: $scriptdir/$stuk | $scriptdir/$gimn"
  exit 1
fi
# Валідація гучності
for v in "$stukVol" "$gimnVol"; do
  case "$v" in ''|*[!0-9]*) echo "Некоректна гучність: $v"; exit 1;; esac
  if [ "$v" -lt 0 ] || [ "$v" -gt 100 ]; then
    echo "Гучність поза межами 0-100: $v"; exit 1
  fi
done
# Необхідні утиліти
need_amixer=false
case "$metod" in
  1) command -v aplay >/dev/null || { echo "aplay не знайдена (alsa-utils?)"; exit 1; }; need_amixer=true ;;
  2) command -v cvlc  >/dev/null || { echo "cvlc не знайдена (vlc-nox?)";    exit 1; }; need_amixer=true ;;
  *) echo "Невірно вказаний метод"; exit 1 ;;
esac
if $need_amixer; then
  command -v amixer >/dev/null || { echo "amixer не знайдена (alsa-utils?)"; exit 1; }
fi
if [ "$enablePing" = true ]; then
  command -v speaker-test >/dev/null || { echo "speaker-test не знайдено (alsa-utils) для пінга"; exit 1; }
fi

# Стар стоп запис з часом
log_start() { [ "$StartStopLog" = true ] && echo "$(date '+%Y-%m-%d %H:%M:%S') - Відтворення запущено"; }
log_end()   { [ "$StartStopLog" = true ] && echo "$(date '+%Y-%m-%d %H:%M:%S') - Відтворення завершено"; }

# «Пінг» — через ALSA, незалежно від обраного методу.
do_ping() {
  if [ "$enablePing" = true ]; then
    amixer -q -c "$amixer_card" sset "$mixerCtl" "${stukVol}%" unmute
    speaker-test -D hw:${amixer_card},0 -t sine -f "$pingFreq" >/dev/null 2>&1 &
    _ping_pid=$!
    sleep "$(awk "BEGIN{print $pingDur/1000}")"
    kill -TERM "$_ping_pid" 2>/dev/null
    wait "$_ping_pid" 2>/dev/null
    sleep 0.1
  fi
}

alsaMetod () {
  log_start
  do_ping
  amixer -q -c "$amixer_card" sset "$mixerCtl" "${stukVol}%"
  aplay -D hw:${amixer_card},0 "$scriptdir/$stuk"
  sleep "$delayt"
  amixer -q -c "$amixer_card" sset "$mixerCtl" "${gimnVol}%"
  aplay -D hw:${amixer_card},0 "$scriptdir/$gimn"
}
cvlcMetod () {
  log_start
  do_ping
  amixer -q -c "$amixer_card" sset "$mixerCtl" "${stukVol}%"
  cvlc --no-video --intf dummy --aout=alsa --alsa-audio-device=hw:${amixer_card},0 --play-and-exit "$scriptdir/$stuk"
  sleep "$delayt"
  amixer -q -c "$amixer_card" sset "$mixerCtl" "${gimnVol}%"
  cvlc --no-video --intf dummy --aout=alsa --alsa-audio-device=hw:${amixer_card},0 --play-and-exit "$scriptdir/$gimn"
}

# ===== Запуск =====
case "$metod" in
  1) alsaMetod ;;
  2) cvlcMetod ;;
esac

log_end

# Після завершення прибрати гучність (встановити на 0)
if [ "$muteEnd" = true ]; then
  amixer -q -c "$amixer_card" sset "$mixerCtl" 0%
fi
