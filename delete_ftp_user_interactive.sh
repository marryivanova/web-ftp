#!/bin/bash
# save as: delete_ftp_user_interactive.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  УДАЛЕНИЕ FTP ПОЛЬЗОВАТЕЛЯ"
echo "========================================"

echo ""
echo "Список FTP пользователей:"
echo "-----------------------"

i=1
declare -A USERS_MAP

for USER_DIR in /home/*; do
    USER=$(basename "$USER_DIR")

    if [[ "$USER" == "lost+found" ]] || [[ ! -d "$USER_DIR" ]]; then
        continue
    fi
    if [ -f /etc/vsftpd.user_list ] && grep -q "^$USER$" /etc/vsftpd.user_list; then
        USERS_MAP[$i]="$USER"

        if [ -f /etc/vsftpd.chroot_list ] && grep -q "^$USER$" /etc/vsftpd.chroot_list; then
            echo "  $i) $USER ${YELLOW}[ADMIN]${NC}"
        else
            echo "  $i) $USER"
        fi

        i=$((i+1))
    fi
done

echo "  q) Отмена"
echo "-----------------------"

# Выбор пользователя
read -p "Выберите номер пользователя для удаления: " CHOICE

if [[ "$CHOICE" == "q" ]] || [[ -z "$CHOICE" ]]; then
    echo "Отменено"
    exit 0
fi

USERNAME="${USERS_MAP[$CHOICE]}"

if [ -z "$USERNAME" ]; then
    echo -e "${RED}Ошибка: Неверный выбор${NC}"
    exit 1
fi

echo ""
echo "Выбран пользователь: ${BLUE}$USERNAME${NC}"

# Варианты удаления
echo ""
echo "Варианты удаления:"
echo "1) Полное удаление (пользователь + файлы)"
echo "2) Только отключить FTP (оставить файлы)"
echo "3) Архивировать и удалить"
echo "4) Отмена"
read -p "Выберите действие [1]: " ACTION
ACTION=${ACTION:-1}

case $ACTION in
    1)
        # Полное удаление
        echo ""
        echo "${RED}ПОЛНОЕ УДАЛЕНИЕ${NC}"
        echo "Будет удалено:"
        echo "  • Пользователь $USERNAME"
        echo "  • Группа $USERNAME"
        echo "  • Директория /home/$USERNAME"
        echo "  • Все файлы пользователя"

        read -p "Вы уверены? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Отменено"
            exit 0
        fi

        # Удалить из списков
        sudo sed -i "/^$USERNAME$/d" /etc/vsftpd.user_list 2>/dev/null
        sudo sed -i "/^$USERNAME$/d" /etc/vsftpd.chroot_list 2>/dev/null

        # Убить процессы
        sudo pkill -9 -u "$USERNAME" 2>/dev/null

        # Удалить пользователя
        sudo userdel -r "$USERNAME"

        echo -e "${GREEN}✓ Пользователь полностью удален${NC}"
        ;;

    2)
        # Только отключить FTP
        echo ""
        echo "${YELLOW}ОТКЛЮЧЕНИЕ FTP ДОСТУПА${NC}"
        echo "Пользователь останется в системе, но не сможет"
        echo "подключаться по FTP"

        # Удалить только из списков FTP
        sudo sed -i "/^$USERNAME$/d" /etc/vsftpd.user_list 2>/dev/null

        sudo sed -i "/^$USERNAME$/d" /etc/vsftpd.chroot_list 2>/dev/null

        # Заблокировать аккаунт
        sudo usermod -L "$USERNAME"

        echo -e "${GREEN}✓ FTP доступ отключен${NC}"
        echo "Пользователь $USERNAME остался в системе"
        echo "Файлы в /home/$USERNAME сохранены"
        ;;

    3)
        # Архивировать и удалить
        echo ""
        echo "${BLUE}АРХИВИРОВАНИЕ И УДАЛЕНИЕ${NC}"

        BACKUP_DIR="/backup/deleted_users"
        BACKUP_FILE="$BACKUP_DIR/${USERNAME}_$(date +%Y%m%d_%H%M%S).tar.gz"

        sudo mkdir -p "$BACKUP_DIR"

        # Архивировать домашнюю директорию
        if [ -d "/home/$USERNAME" ]; then
            sudo tar -czf "$BACKUP_FILE" -C /home "$USERNAME"
            echo "✓ Создан архив: $BACKUP_FILE"

            # Удалить пользователя
            sudo sed -i "/^$USERNAME$/d" /etc/vsftpd.user_list 2>/dev/null
            sudo sed -i "/^$USERNAME$/d" /etc/vsftpd.chroot_list 2>/dev/null
            sudo pkill -9 -u "$USERNAME" 2>/dev/null
            sudo userdel -r "$USERNAME"

            echo -e "${GREEN}✓ Пользователь удален, архив сохранен${NC}"
        else
            echo -e "${RED}Ошибка: Домашняя директория не найдена${NC}"
        fi
        ;;

    *)
        echo "Отменено"
        exit 0
        ;;
esac

sudo systemctl restart vsftpd
echo -e "${GREEN}✓ vsftpd перезапущен${NC}"