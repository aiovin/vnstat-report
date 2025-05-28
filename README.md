# vnstat-report
Bash скрипт для парсинга `vnstat --oneline` и отправки результатов в Telegram или ntfy.sh

<img src="https://raw.githubusercontent.com/aiovin/vnstat-report/refs/heads/main/total.png"> <img src="https://raw.githubusercontent.com/aiovin/vnstat-report/refs/heads/main/daily.png">

## 📥 Скачайте скрипт

Скачайте скрипт в любое удобное место и сделайте его исполняемым:

```bash
curl -o vnstat-report.sh https://raw.githubusercontent.com/aiovin/vnstat-report/refs/heads/main/vnstat-report.sh
```

```bash
chmod +x vnstat-report.sh
```

## ⚙️ Настройка

Откройте скрипт и отредактируйте переменные:

```
MSG_TYPE="tg"                    # Тип уведомлений (tg/ntfy)

BOT_TOKEN="ваш_токен"            # Telegram токен
CHAT_ID="ваш_chat_id"            # ID пользователя/чата

NTFY_TOPIC="ваш_топик"           # Ваш топик ntfy
```
Параметры для неиспользуемого типа уведомлений можно не заполнять.

## Определите тип отчета
Добавьте необходимые ключи к команде запуска скрипта.

| Ключ             | Описание                                                              |
| ---------------- | --------------------------------------------------------------------- |
| Без ключей      | Придет полный отчет, включающий трафик за день, месяц и всё время                    |
| `-daily`         | Отчет за день  |
| `-monthly` | Отчет за месяц    |
| `-total` | Отчет за все время    |
| `-msgtype тип` | Куда отправить уведомление (tg/ntfy)    |
| `-host имя` | Альтернативное имя хоста в заголовке сообщения    |
| `-debug` | Посмотреть, какое сообщение будет отправлено, но не отправлять его    |

### Примеры
`bash vnstat-report.sh -debug` Не отправлять сообщение но вывести на экран его текст<br>
`bash vnstat-report.sh -daily` Отправить статистику за сегодняшний день<br>
#### Ключи можно комбинировать, например:<br>
Посмотреть на сформированное сообщение но не отправлять<br>
`bash vnstat-report.sh -daily -monthly -msgtype ntfy -host "MyVPS" -debug`<br><br>
Удалите `-debug`, чтобы действительно отправить отчет (не забудьте заполнить необходимые данные для tg или ntfy!)

## 📅 Добавление в cron
Определившись какие отчеты вам нужны, добавьте соответствующие задачи в cron

```
crontab -e
```

Добавьте задачу.<br>
Примеры:

Ежедневный отчет в 12 ночи
```
0 0 * * * /полный/путь/к/скрипту/vnstat-report.sh -daily >> /var/tmp/vnstat-report.log 2>&1
```

Еженедельный (В 00:00 каждого понедельника)
```
0 0 * * 1 /полный/путь/к/скрипту/vnstat-report.sh >> /var/tmp/vnstat-report.log 2>&1
```

Ежемесячный (В 23:00 в последний день каждого месяца)
```
0 23 28-31 * * [ "$(date +\%d -d tomorrow)" = "01" ] && /полный/путь/к/скрипту/vnstat-report.sh -monthly >> /var/tmp/vnstat-report.log 2>&1
```

### Файл логов

```
/var/tmp/vnstat-report.log
```

> [!TIP]
> Установите утилиту `jq` для читабельного ответа от серверов при отправке сообщений<br>
> `sudo apt update && sudo apt install jq` Для Debian/Ubuntu
