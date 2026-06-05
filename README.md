# Web FTP

Веб-интерфейс для управления файлами через FTP/SSH.

Скачать клиент -> https://filezilla.ru/?ysclid=ml9az4od1v881979204

## Как подключиться к серверу:

### Предварительные требования:
1. **Настройте доступ по SSH** на целевом сервере
2. Убедитесь, что **открыты необходимые порты** (обычно 21 для FTP, 22 для SSH)
3. Иметь **действительные учетные данные** для подключения

### Шаги подключения:
1. **Введите данные сервера:**
   - **Хост/IP адрес**
   - **Порт** (по умолчанию: 21 для FTP, 22 для SSH)
   - **Имя пользователя**
   - **Пароль**

2. **Выберите тип подключения:**
   - **FTP** - стандартное FTP соединение
   - **SFTP** - безопасное соединение через SSH (рекомендуется)
   - **FTPS** - FTP поверх SSL/TLS

3. **Нажмите кнопку "Подключиться"**

## Возможности:

### Основные функции:
- 📁 **Просмотр файловой структуры**
- 📤 **Загрузка файлов** на сервер
- 📥 **Скачивание файлов** с сервера
- ✏️ **Редактирование текстовых файлов**
- 🗑️ **Удаление файлов и папок**
- 📂 **Создание новых папок**
- 🔄 **Переименование файлов**
- 📊 **Просмотр информации о файлах** (размер, права доступа, дата изменения)

### Дополнительные возможности:
- **Поддержка drag-and-drop** для загрузки файлов
- **Множественный выбор** файлов
- **Поиск** по файловой системе
- **Сортировка** по имени, размеру или дате
- **Запоминание** последних подключений

## Безопасность:

### Рекомендации:
- 🔒 Используйте **SFTP** вместо обычного FTP
- 🛡️ Регулярно **обновляйте пароли** доступа
- 👥 Настраивайте **права доступа** минимально необходимым
- 📝 Ведите **журнал подключений**

### Поддерживаемые протоколы безопасности:
- **SSH-ключи** (RSA, DSA, Ed25519)
- **SSL/TLS шифрование**
- **Двухфакторная аутентификация**

## Устранение неполадок:

### Частые проблемы:
1. **Ошибка подключения:**
   - Проверьте правильность введенных данных
   - Убедитесь, что сервер доступен
   - Проверьте настройки брандмауэра

2. **Проблемы с правами доступа:**
   - Убедитесь, что у пользователя есть необходимые права
   - Проверьте права на папки (chmod)

3. **Медленное соединение:**
   - Проверьте скорость интернета
   - Уменьшите размер загружаемых файлов
   - Используйте сжатие при передаче

## Поддерживаемые платформы:
- ✅ **Linux**
- ✅ **Windows Server**
- ✅ **macOS**
- ✅ **BSD-системы**

## Как подключиться на сервак:

1. ssh root@ ...
2. Преварительно настроить доступ по ssh.

## Базовый конфиг для настройки прав\ролей:
```
Настройка:
# Uncomment this to indicate that vsftpd use a utf8 filesystem.
#utf8_filesystem=YES
# Базовые настройки
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES

# БЕЗОПАСНОСТЬ и ЧАСТНЫЕ ПАПКИ
chroot_local_user=YES
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd.chroot_list

allow_writeable_chroot=YES
user_sub_token=$USER
local_root=/home/$USER/ftp
userlist_enable=YES
userlist_file=/etc/vsftpd.user_list
userlist_deny=NO

# Пассивный режим (важно для клиентов за NAT)
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
pasv_address=....

# Лимиты (поможет с уборкой и трафиком)
max_clients=50
max_per_ip=5
local_umask=022
idle_session_timeout=600
data_connection_timeout=120
ftpd_banner=Добро пожаловать на FTP-сервер.
```

## Команды для аминистрирования

### Мониторинг подключений

- **Все подключения vsftpd:**
  - netstat -an | grep :21 | wc -l

- **Только установленные соединения:**
  - netstat -an | grep :21 | grep ESTABLISHED | wc -l

### Статус firewall

- **Чек статуса активен - не активен (надо чтобы всегда был включен):**
  - netstat -an | grep :21 | wc -l

### Частые команды vsftpd

- **Логи vsftpd:**
  - tail -f /var/log/vsftpd.log
  - tail -f /var/log/xferlog

- **Команды перезапуска**
    - systemctl restart vsftpd
    - systemctl enable vsftpd

---

**Скрипты для автоматизации процесов.**


Путь хранения: `/usr/local/bin/change_ftp_login.sh`

## Добавление юзера

- Запустить -> **sudo create_ftp_user.sh**

```bash
root@corvusweb-vps-16:~# sudo create_ftp_user.sh
========================================
  МАСТЕР СОЗДАНИЯ FTP ПОЛЬЗОВАТЕЛЯ
========================================

Введите имя пользователя: anastasiya.lokek

ℹ ИНФО: Выбранное имя: anastasiya.lokek

Создать администратора? (y/N): т
ℹ ИНФО: Будет создан обычный пользователь (изолирован)

----------------------------------------
Домашняя директория [/home/anastasiya.lokek]:

ℹ ИНФО: Создание пользователя anastasiya.lokek...
✓ УСПЕХ: Пользователь создан

ℹ ИНФО: Установка пароля для anastasiya.lokek
----------------------------------------
ВВЕДИТЕ ПАРОЛЬ (он будет скрыт при вводе):
New password:
Retype new password:
passwd: password updated successfully
----------------------------------------
✓ УСПЕХ: Пароль установлен

ℹ ИНФО: Создание структуры папок...

Выберите структуру папок:
1) Стандартная (ftp/upload)
2) Минимальная (только upload)
3) Расширенная (ftp/upload, ftp/download, ftp/public)
Выбор [1]: 1
ℹ ИНФО: Создана стандартная структура

ℹ ИНФО: Настройка FTP доступа...
✓ УСПЕХ: Добавлен в vsftpd.user_list

ℹ ИНФО: Дополнительные настройки...
Отключить shell доступ для пользователя? (y/N): т

========================================
✓ УСПЕХ: ПОЛЬЗОВАТЕЛЬ УСПЕШНО СОЗДАН!
========================================

ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ:
────────────────────────────
Имя:           anastasiya.lokek
Домашняя папка: /home/anastasiya.lokek
Тип доступа:   Обычный (изолирован)

ДОСТУП ПО FTP:
  Папка:      /home/anastasiya.lokek/ftp
  Загрузки:   /home/anastasiya.lokek/ftp/upload

ДЕЙСТВИЯ ДЛЯ ЗАВЕРШЕНИЯ:
────────────────────────────
1. Перезапустить FTP сервер:
   sudo systemctl restart vsftpd

2. Проверить подключение:
   ftp localhost
   Логин: anastasiya.lokek

3. Для админа - создать ссылки на пользователей:
========================================

Перезапустить vsftpd сейчас? (Y/n):

✓ УСПЕХ: vsftpd перезапущен

ℹ ИНФО: Готово! Пользователь anastasiya.lolkek создан.
```

## Удалить юзера

- Запустить -> **sudo delete_ftp_user_interactive.sh**

```bash
========================================
  УДАЛЕНИЕ FTP ПОЛЬЗОВАТЕЛЯ
========================================

Список FTP пользователей:
-----------------------
  1) adminftp \033[1;33m[ADMIN]\033[0m
  2) anastasiya.lokek@lokek.top
  3) ya.lokek@lokek.top
  4) nika.kostyukevich
  5) ya.lokek@lokek.top
  6) yuriy.lokek@lokek.top
  q) Отмена
-----------------------
Выберите номер пользователя для удаления: q
Отменено
root@corvusweb-vps-16:~# echo "anastasiya.lokek" | sudo tee -a /etc/vsftpd.user_list
anastasiya.lolkek
root@corvusweb-vps-16:~# sudo delete_ftp_user_interactive.sh
========================================
  УДАЛЕНИЕ FTP ПОЛЬЗОВАТЕЛЯ
========================================

Список FTP пользователей:
-----------------------
  1) adminftp \033[1;33m[ADMIN]\033[0m
  2) anastasiya.lokek@lokek.top
  3) ya.lokek@lokek.top
  4) nika.kostyukevich
  5) ya.lokek@lokek.top
  6) yuriy.lokek@lokek.top
  q) Отмена
-----------------------
Выберите номер пользователя для удаления: q
Отменено
root@corvusweb-vps-16:~# sudo delete_ftp_user_interactive.sh
========================================
  УДАЛЕНИЕ FTP ПОЛЬЗОВАТЕЛЯ
========================================

Список FTP пользователей:
-----------------------
  1) adminftp \033[1;33m[ADMIN]\033[0m
  2) anastasiya.lokek@lokek.top
  3) ya.lokek@lokek.top
  4) nika.kostyukevich
  5) ya.lokek@lokek.top
  6) yuriy.lokek@lokek.top
  q) Отмена
-----------------------
Выберите номер пользователя для удаления: 3

Выбран пользователь: \033[0;34manastasiya.lolkek\033[0m

Варианты удаления:
1) Полное удаление (пользователь + файлы)
2) Только отключить FTP (оставить файлы)
3) Архивировать и удалить
4) Отмена
Выберите действие [1]: 1

\033[0;31mПОЛНОЕ УДАЛЕНИЕ\033[0m
Будет удалено:
  • Пользователь anastasiya.selivanova
  • Группа anastasiya.lolkek
  • Директория /home/anastasiya.lolkek
  • Все файлы пользователя
Вы уверены? (y/N): y
userdel: group anastasiya.lolkek a not removed because it has other members.
userdel: anastasiya.selivanova mail spool (/var/mail/anastasiya.lolkek) not found
✓ Пользователь полностью удален
✓ vsftpd перезапущен
```

## Сменить  логин юзера

- Запустить -> **sudo change_ftp_login.sh**

```bash
========================================
  СМЕНА ЛОГИНА FTP ПОЛЬЗОВАТЕЛЯ
========================================

Существующие FTP пользователи:
-----------------------------
  - .
  - ..
  - adminftp
  anastasiya.lokek@lokek.top
  ya.lokek@lokek.top
  nika.kostyukevich
  ya.lokek@lokek.top
  yuriy.lokek@lokek.top
-----------------------------
Введите ТЕКУЩИЙ логин: anastasiya.lolkek
Введите НОВЫЙ логин: anastasiya.lokek@lokek.top

Подтвердите смену:
  Старый логин: anastasiya.lolkek
  Новый логин:  anastasiya.lokek@lokek.top
Продолжить? (y/N): y

Выполняю смену логина...
1. Останавливаю процессы пользователя...
2. Меняю имя пользователя...
usermod: invalid user name 'aanastasiya.lokek@lokek.top': use --badname to ignore
3. Меняю имя группы...
4. Меняю домашнюю директорию...
usermod: user 'anastasiya.lokek@lokek.top' does not exist
5. Обновляю списки FTP...
  ✓ Обновлен vsftpd.user_list
6. Перезапускаю vsftpd...

✓ Логин успешно изменен!

Новые данные для входа:
  Логин:    anastasiya.lokek@lokek.top
  Пароль:   остался прежним
  Папка:    /home/anastasiya.lokek@lokek.top
```