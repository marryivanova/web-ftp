#!/bin/bash
# save as: create_ftp_user_interactive.sh
# Просто запустите: sudo ./create_ftp_user_interactive.sh

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

error() { echo -e "${RED}✗ ОШИБКА:${NC} $1"; }
success() { echo -e "${GREEN}✓ УСПЕХ:${NC} $1"; }
info() { echo -e "${BLUE}ℹ ИНФО:${NC} $1"; }
warning() { echo -e "${YELLOW}⚠ ПРЕДУПРЕЖДЕНИЕ:${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    error "Запустите скрипт с sudo: sudo $0"
    exit 1
fi

echo "========================================"
echo "  МАСТЕР СОЗДАНИЯ FTP ПОЛЬЗОВАТЕЛЯ"
echo "========================================"
echo ""

# 1. Запрос имени пользователя
while true; do
    read -p "Введите имя пользователя: " USERNAME

    if [ -z "$USERNAME" ]; then
        error "Имя пользователя не может быть пустым!"
        continue
    fi

    # Проверка существования
    if id "$USERNAME" &>/dev/null; then
        error "Пользователь '$USERNAME' уже существует!"
        read -p "Попробовать другое имя? (Y/n): " RETRY
        if [[ "$RETRY" =~ ^[Nn] ]]; then
            exit 1
        fi
        continue
    fi

    break
done

echo ""
info "Выбранное имя: $USERNAME"
echo ""

# 2. Запрос типа пользователя
read -p "Создать администратора? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ADMIN_MODE=true
    info "Будет создан АДМИНИСТРАТОР (видит все папки)"
else
    ADMIN_MODE=false
    info "Будет создан обычный пользователь (изолирован)"
fi

echo ""
echo "----------------------------------------"

# 3. Запрос домашней директории
DEFAULT_HOME="/home/$USERNAME"
read -p "Домашняя директория [$DEFAULT_HOME]: " USER_HOME
USER_HOME=${USER_HOME:-$DEFAULT_HOME}

# 4. Создание пользователя
echo ""
info "Создание пользователя $USERNAME..."
sudo useradd -m -d "$USER_HOME" -s /bin/bash "$USERNAME"

if [ $? -ne 0 ]; then
    error "Не удалось создать пользователя!"
    exit 1
fi
success "Пользователь создан"

# 5. Установка пароля
echo ""
info "Установка пароля для $USERNAME"
echo "----------------------------------------"
echo "ВВЕДИТЕ ПАРОЛЬ (он будет скрыт при вводе):"
sudo passwd "$USERNAME"

if [ $? -ne 0 ]; then
    error "Ошибка при установке пароля!"

    # Откат: удаляем пользователя если пароль не установлен
    read -p "Удалить созданного пользователя? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo userdel -r "$USERNAME"
        info "Пользователь удален"
    fi
    exit 1
fi
echo "----------------------------------------"
success "Пароль установлен"

# 6. Создание структуры папок
echo ""
info "Создание структуры папок..."

# Запрос о структуре
echo ""
echo "Выберите структуру папок:"
echo "1) Стандартная (ftp/upload)"
echo "2) Минимальная (только upload)"
echo "3) Расширенная (ftp/upload, ftp/download, ftp/public)"
read -p "Выбор [1]: " STRUCTURE
STRUCTURE=${STRUCTURE:-1}

case $STRUCTURE in
    1)
        sudo mkdir -p "$USER_HOME/ftp/upload"
        sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/ftp/upload"
        sudo chmod 755 "$USER_HOME/ftp"
        sudo chmod 775 "$USER_HOME/ftp/upload"
        info "Создана стандартная структура"
        ;;
    2)
        sudo mkdir -p "$USER_HOME/upload"
        sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/upload"
        sudo chmod 775 "$USER_HOME/upload"
        info "Создана минимальная структура"
        ;;
    3)
        sudo mkdir -p "$USER_HOME/ftp/upload"
        sudo mkdir -p "$USER_HOME/ftp/download"
        sudo mkdir -p "$USER_HOME/ftp/public"
        sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/ftp"
        sudo chmod 755 "$USER_HOME/ftp"
        sudo chmod 775 "$USER_HOME/ftp/upload"
        sudo chmod 755 "$USER_HOME/ftp/download"
        sudo chmod 777 "$USER_HOME/ftp/public"
        info "Создана расширенная структура"
        ;;
    *)
        error "Неверный выбор, используется стандартная структура"
        sudo mkdir -p "$USER_HOME/ftp/upload"
        sudo chown -R "$USERNAME:$USERNAME" "$USER_HOME/ftp/upload"
        sudo chmod 755 "$USER_HOME/ftp"
        sudo chmod 775 "$USER_HOME/ftp/upload"
        ;;
esac

# 7. Настройка FTP
echo ""
info "Настройка FTP доступа..."

# Добавление в vsftpd.user_list
if [ -f /etc/vsftpd.user_list ]; then
    if grep -q "^$USERNAME$" /etc/vsftpd.user_list; then
        warning "Пользователь уже есть в vsftpd.user_list"
    else
        echo "$USERNAME" | sudo tee -a /etc/vsftpd.user_list > /dev/null
        success "Добавлен в vsftpd.user_list"
    fi
else
    warning "Файл /etc/vsftpd.user_list не найден!"
    read -p "Создать файл? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "$USERNAME" | sudo tee /etc/vsftpd.user_list > /dev/null
        success "Файл создан и пользователь добавлен"
    fi
fi

# Для администратора - добавление в chroot_list
if [ "$ADMIN_MODE" = true ]; then
    if [ -f /etc/vsftpd.chroot_list ]; then
        if grep -q "^$USERNAME$" /etc/vsftpd.chroot_list; then
            warning "Пользователь уже есть в vsftpd.chroot_list"
        else
            echo "$USERNAME" | sudo tee -a /etc/vsftpd.chroot_list > /dev/null
            success "Добавлен в vsftpd.chroot_list (видит всё)"
        fi
    else
        warning "Файл /etc/vsftpd.chroot_list не найден!"
        read -p "Создать файл? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "$USERNAME" | sudo tee /etc/vsftpd.chroot_list > /dev/null
            success "Файл создан и пользователь добавлен"
        fi
    fi
fi

# 8. Дополнительные настройки
echo ""
info "Дополнительные настройки..."

read -p "Отключить shell доступ для пользователя? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo usermod -s /sbin/nologin "$USERNAME"
    info "Shell доступ отключен"
fi


if command -v setquota &> /dev/null; then
    read -p "Установить дисковую квоту? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Лимит (например, 100M, 1G): " QUOTA_LIMIT
        if [ -n "$QUOTA_LIMIT" ]; then
            sudo setquota -u "$USERNAME" 0 "$QUOTA_LIMIT" 0 0 /
            success "Квота установлена: $QUOTA_LIMIT"
        fi
    fi
fi

# 9. Итог
echo ""
echo "========================================"
success "ПОЛЬЗОВАТЕЛЬ УСПЕШНО СОЗДАН!"
echo "========================================"
echo ""
echo "ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ:"
echo "────────────────────────────"
echo "Имя:           $USERNAME"
echo "Домашняя папка: $USER_HOME"
echo "Тип доступа:   $(if [ "$ADMIN_MODE" = true ]; then echo "Администратор (видит всё)"; else echo "Обычный (изолирован)"; fi)"
echo ""

if [ $STRUCTURE -eq 1 ]; then
    echo "ДОСТУП ПО FTP:"
    echo "  Папка:      $USER_HOME/ftp"
    echo "  Загрузки:   $USER_HOME/ftp/upload"
elif [ $STRUCTURE -eq 2 ]; then
    echo "ДОСТУП ПО FTP:"
    echo "  Папка:      $USER_HOME"
    echo "  Загрузки:   $USER_HOME/upload"
elif [ $STRUCTURE -eq 3 ]; then
    echo "ДОСТУП ПО FTP:"
    echo "  Папка:      $USER_HOME/ftp"
    echo "  Загрузки:   $USER_HOME/ftp/upload"
    echo "  Скачивание: $USER_HOME/ftp/download"
    echo "  Общее:      $USER_HOME/ftp/public"
fi

echo ""
echo "ДЕЙСТВИЯ ДЛЯ ЗАВЕРШЕНИЯ:"
echo "────────────────────────────"
echo "1. Перезапустить FTP сервер:"
echo "   sudo systemctl restart vsftpd"
echo ""
echo "2. Проверить подключение:"
echo "   ftp localhost"
echo "   Логин: $USERNAME"
echo ""
echo "3. Для админа - создать ссылки на пользователей:"
if [ "$ADMIN_MODE" = true ]; then
    echo "   sudo mkdir -p $USER_HOME/ftp_view"
    echo "   sudo ln -s /home/* $USER_HOME/ftp_view/ 2>/dev/null"
fi

echo "========================================"
echo ""

# 10. Перезапуск vsftpd
read -p "Перезапустить vsftpd сейчас? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    sudo systemctl restart vsftpd
    if [ $? -eq 0 ]; then
        success "vsftpd перезапущен"
    else
        error "Ошибка при перезапуске vsftpd"
    fi
fi

echo ""
info "Готово! Пользователь $USERNAME создан."