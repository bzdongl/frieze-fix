#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NONE='\033[0m'

PROMETHEUS="$BLUE--------------------------------------------------------------------$NONE$GREEN
    0000  0000  00000 0    0 00000 00000 0   0 00000 0   0 00000
    0   0 0   0 0   0 00  00 0       0   0   0 0     0   0 0     
    0000  0000  0   0 0 00 0 00000   0   00000 00000 0   0 00000 
    0     0  0  0   0 0    0 0       0   0   0 0     0   0     0 
    0     0   0 00000 0    0 00000   0   0   0 00000 00000 00000$NONE
$BLUE-------------------------------------------------------------------- $NONE"

clear
echo -e "$PROMETHEUS"
sleep 0.2

DIRP=$(pwd)
export DIRP

# Создаём директории
for d in scripts configs files logs; do
    rm -rf "$DIRP/$d"
    mkdir -p "$DIRP/$d"
done

# Проверка интернета
check_internet() {
    host=$1
    echo -e "GET / HTTP/1.0\n\n" | nc "$host" 80 > /dev/null 2>&1
    return $?
}

if ! check_internet "google.com"; then
    echo -e "$RED Нет соединения с интернетом! $NONE"
    read -p "Продолжить? (y/n): " choice
    [[ $choice =~ [Nn] ]] && exit
fi

if ! check_internet "pm.freize.net"; then
    echo -e "$RED Удалённый сервер не отвечает! $NONE"
    read -p "Продолжить? (y/n): " choice
    [[ $choice =~ [Nn] ]] && exit
fi

# Зависимости
DEPENDENCIES="ca-certificates build-essential gawk texinfo pkg-config gettext automake libtool bison flex zlib1g-dev libgmp3-dev libmpfr-dev libmpc-dev git zip sshpass mc curl python3 expect bc telnet openssh-client tftpd-hpa libid3tag0-dev gperf libltdl-dev autopoint"

export DEBIAN_FRONTEND=noninteractive

# Завершаем зависшие установки
sudo dpkg --configure -a
sudo apt-get install -f -y

# Прогресс-бар
total=$(echo $DEPENDENCIES | wc -w)
count=0

for pkg in $DEPENDENCIES; do
    count=$((count+1))
    echo -ne "$YELLOW Устанавливаем $pkg ($count/$total)... $NONE"
    timeout 300 sudo apt-get -y install "$pkg" &>/dev/null
    if [ $? -eq 124 ]; then
        echo -e "$RED Превышено время установки $pkg, пропускаем $NONE"
    else
        echo -e "$GREEN Установлен $pkg $NONE"
    fi
done

# Загрузка и распаковка скриптов
wget -O "$DIRP/update.tar" http://pm.freize.net/scripts/update.tar &>/dev/null
wget -O "$DIRP/files/loki.tar" http://pm.freize.net/scripts/loki.tar &>/dev/null

tar -xvf "$DIRP/files/loki.tar" configs/git.sh -C configs >/dev/null 2>&1
tar -xvf "$DIRP/files/loki.tar" configs/uboot.sh -C configs >/dev/null 2>&1
tar -xvf "$DIRP/update.tar"
rm -f "$DIRP/update.tar"

# Запуск обновляющих скриптов
./scripts/up2.sh

echo -e "$BLUE Скрипты:$NONE$GREEN OK $NONE"
sleep 0.1

exec ./start.sh
