#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ==== НАСТРОЙКИ ====
MSG_TYPE="tg"

BOT_TOKEN="your_token"
CHAT_ID="your_id"
NTFY_TOPIC="your_topic"

# Установить тип отчета по умолчанию (все нули - полный отчет)
SHOW_DAILY=0
SHOW_MONTHLY=0
SHOW_TOTAL=0

DEBUG=0
HOST=$(hostname)

# ====

for cmd in vnstat curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Ошибка: для работы требуется утилита '$cmd'. Скрипт завершён."
    exit 1
  fi
done

# ====

while [[ $# -gt 0 ]]; do
    case "$1" in

        -debug) DEBUG=1
                shift ;;

        -msgtype) if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                MSG_TYPE="$2"
                shift 2
            else
                echo "Ошибка: опция -msgtype требует указания типа уведомлений."
                exit 1
            fi ;;

        -host) if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                HOST="$2"
                shift 2
            else
                echo "Ошибка: опция -host требует указания имени хоста."
                exit 1
            fi ;;

        -daily) SHOW_DAILY=1
                shift ;;

        -monthly) SHOW_MONTHLY=1
                shift ;;

        -total) SHOW_TOTAL=1
                shift ;;

        -*) echo "Неизвестный аргумент: $1"; exit 1 ;;
        *) echo "Неизвестный аргумент: $1"; exit 1 ;;
    esac
done

# ====

# По умолчанию если запускать скрипт без каких либо ключей, то отправится полный вывод vnstat - за день, за месяц и за все время
if [ "$SHOW_DAILY" -eq 0 ] && [ "$SHOW_MONTHLY" -eq 0 ] && [ "$SHOW_TOTAL" -eq 0 ]; then
    SHOW_DAILY=1
    SHOW_MONTHLY=1
    SHOW_TOTAL=1
fi

send_message() {
  local MSG_TYPE="$1"
  local MESSAGE="$2"

  case "$MSG_TYPE" in
      "tg")
          curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
               -d chat_id="${CHAT_ID}" \
               -d text="${MESSAGE}" \
               -d parse_mode="HTML" | (command -v jq &>/dev/null && jq . || { cat; echo; })
          ;;

      "ntfy")
          # Из MESSAGE отделяем заголовок (имя хоста) и тело (само сообщение)
          local TITLE="${MESSAGE%%$'\n'*}"
          local BODY="${MESSAGE#*$'\n'}"

          if [[ "$BODY" == "$MESSAGE" ]]; then
            TITLE=""
          fi

          curl -s -X POST "https://ntfy.sh/${NTFY_TOPIC}" \
               -H "Title: ${TITLE}" \
               -H "Priority: high" \
               -d "${BODY}" | (command -v jq &>/dev/null && jq . || cat)
          ;;

      *)
          echo "Ошибка: недопустимый тип уведомлений. Поддерживаются: 'tg', 'ntfy'."
          exit 1
          ;;
  esac
}

# ====

generate_vnstat_report() {
  local oneline_output
  oneline_output="$(vnstat --oneline)"

  IFS=';' read -r STATUS IFACE DATE RX_DAILY TX_DAILY TOTAL_DAILY SPEED_DAILY \
                  MONTH RX_MONTH TX_MONTH TOTAL_MONTH SPEED_MONTH \
                  RX_ALL TX_ALL TOTAL_ALL <<< "$oneline_output"

  local report="📊 ${HOST^} | Отчет vnStat"

  # ОТЧЕТ ЗА ДЕНЬ
  [[ $SHOW_DAILY -eq 1 ]] && report+="

📅 Сегодня ($DATE):
↓ $RX_DAILY | ↑ $TX_DAILY
= $TOTAL_DAILY (↯ $SPEED_DAILY)"

  # ОТЧЕТ ЗА МЕСЯЦ
  [[ $SHOW_MONTHLY -eq 1 ]] && report+="

🗓️ Месяц ($MONTH):
↓ $RX_MONTH | ↑ $TX_MONTH
= $TOTAL_MONTH (↯ $SPEED_MONTH)"

  # ОТЧЕТ ЗА ВСЕ ВРЕМЯ
  [[ $SHOW_TOTAL -eq 1 ]] && report+="

📦 За все время:
↓ $RX_ALL | ↑ $TX_ALL
= $TOTAL_ALL"

  echo "$report"
}

# ====

MESSAGE="$(generate_vnstat_report)"

if [[ "$DEBUG" -eq 1 ]]; then
    echo "[DEBUG ${SHOW_DAILY}|${SHOW_MONTHLY}|${SHOW_TOTAL} ] Отправляю (как-бы) отчет в '${MSG_TYPE}'. Текст сообщения:"
    echo "$MESSAGE"
else
    echo -e "[$(date +'%d-%m-%y %H:%M:%S %Z')] ${SHOW_DAILY}|${SHOW_MONTHLY}|${SHOW_TOTAL} Отправляю отчет в '${MSG_TYPE}'.."

    # Отправляем уведомление
    send_message "${MSG_TYPE}" "$MESSAGE"
    echo
fi
