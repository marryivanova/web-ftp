echo "========================================"
echo "  СМЕНА ЛОГИНА FTP ПОЛЬЗОВАТЕЛЯ"
echo "========================================"


echo ""
echo "Существующие FTP пользователи:"
echo "-----------------------------"
ls -la /home/ | grep '^d' | awk '{print $9}' | grep -v "lost+found" | while read user; do
    echo "  - $user"
done
echo "-----------------------------"

read -p "Введите ТЕКУЩИЙ логин: " OLD_LOGIN
read -p "Введите НОВЫЙ логин: " NEW_LOGIN

if [ -z "$OLD_LOGIN" ] || [ -z "$NEW_LOGIN" ]; then
    echo -e "${RED}Ошибка: Логины не могут быть пустыми${NC}"
    exit 1
fi

if ! id "$OLD_LOGIN" &>/dev/null; then
    echo -e "${RED}Ошибка: Пользователь '$OLD_LOGIN' не найден${NC}"
    exit 1
fi

if id "$NEW_LOGIN" &>/dev/null; then
    echo -e "${RED}Ошибка: Пользователь '$NEW_LOGIN' уже существует${NC}"
    exit 1
fi

echo ""
echo "Подтвердите смену:"
echo "  Старый логин: $OLD_LOGIN"
echo "  Новый логин:  $NEW_LOGIN"
read -p "Продолжить? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено"
    exit 0
fi

echo ""
echo "Выполняю смену логина..."
echo "1. Останавливаю процессы пользователя..."
sudo pkill -9 -u "$OLD_LOGIN" 2>/dev/null

echo "2. Меняю имя пользователя..."
sudo usermod -l "$NEW_LOGIN" "$OLD_LOGIN"

echo "3. Меняю имя группы..."
sudo groupmod -n "$NEW_LOGIN" "$OLD_LOGIN" 2>/dev/null

echo "4. Меняю домашнюю директорию..."
sudo usermod -d "/home/$NEW_LOGIN" -m "$NEW_LOGIN"

echo "5. Обновляю списки FTP..."
# vsftpd.user_list
if [ -f /etc/vsftpd.user_list ]; then
    if sudo grep -q "^$OLD_LOGIN$" /etc/vsftpd.user_list; then
        sudo sed -i "s/^$OLD_LOGIN$/$NEW_LOGIN/" /etc/vsftpd.user_list
        echo "  ✓ Обновлен vsftpd.user_list"
    fi
fi

# vsftpd.chroot_list
if [ -f /etc/vsftpd.chroot_list ]; then
    if sudo grep -q "^$OLD_LOGIN$" /etc/vsftpd.chroot_list; then
        sudo sed -i "s/^$OLD_LOGIN$/$NEW_LOGIN/" /etc/vsftpd.chroot_list
        echo "  ✓ Обновлен vsftpd.chroot_list"
    fi
fi

echo "6. Перезапускаю vsftpd..."
sudo systemctl restart vsftpd

echo ""
echo -e "${GREEN}✓ Логин успешно изменен!${NC}"
echo ""
echo "Новые данные для входа:"
echo "  Логин:    $NEW_LOGIN"
echo "  Пароль:   остался прежним"
echo "  Папка:    /home/$NEW_LOGIN"
echo ""
echo "Проверьте подключение:"
echo "  ftp localhost"