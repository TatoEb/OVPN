#!/bin/bash
set -e

# Визначення дистрибутива та версії
DISTRO=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
VERSION_ID=$(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"')

echo "[+] Виявлено систему: $DISTRO $VERSION_ID"
echo "[+] Оновлення списку пакетів..."
sudo apt update || true

# Debian 10 (архів)
if [[ "$DISTRO" == "debian" && "$VERSION_ID" == "10" ]]; then
    echo "[!] Debian 10 переміщено в archive.debian.org"
    echo "deb http://archive.debian.org/debian buster main contrib non-free" | sudo tee /etc/apt/sources.list
    echo "deb http://archive.debian.org/debian buster-backports main contrib non-free" | sudo tee /etc/apt/sources.list.d/buster-backports.list
    echo 'Acquire::Check-Valid-Until "false";' | sudo tee /etc/apt/apt.conf.d/99no-check-valid
    sudo apt update
    echo "[+] Встановлюємо WireGuard із архіву..."
    sudo apt -t buster-backports install -y wireguard wireguard-tools wireguard-dkms openresolv
    echo "[✓] Установка завершена для Debian 10 (архів)"
    exit 0
fi

# Debian 11 (backports)
if [[ "$DISTRO" == "debian" && "$VERSION_ID" == "11" ]]; then
    echo "[+] Додаємо backports для Debian 11..."
    echo "deb http://deb.debian.org/debian bullseye-backports main" | sudo tee /etc/apt/sources.list.d/bullseye-backports.list
    sudo apt update
    sudo apt -t bullseye-backports install -y wireguard wireguard-tools wireguard-dkms openresolv
    echo "[✓] Установка завершена для Debian 11"
    exit 0
fi

# Debian 12 та Ubuntu 20.04, 22.04, 24.04
echo "[+] Встановлюємо WireGuard для $DISTRO $VERSION_ID..."

if {
    [[ "$DISTRO" == "ubuntu" && "$VERSION_ID" == "24.04" ]] ||
    [[ "$DISTRO" == "debian" && "$VERSION_ID" == "12" ]];
}; then
    echo "[+] $DISTRO $VERSION_ID: ядро вже містить WireGuard, пропускаємо wireguard-dkms"
    sudo apt install -y wireguard wireguard-tools
else
    sudo apt install -y wireguard wireguard-tools wireguard-dkms
fi

# Встановлення openresolv
if ! command -v resolvconf >/dev/null; then
    if [[ "$DISTRO" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
        echo "[+] У Ubuntu 24.04 openresolv відсутній — встановлюємо вручну..."
        wget -q http://archive.ubuntu.com/ubuntu/pool/universe/o/openresolv/openresolv_3.12.0-1_all.deb
        sudo dpkg -i openresolv_3.12.0-1_all.deb || sudo apt -f install -y
        rm -f openresolv_3.12.0-1_all.deb
    else
        echo "[+] Встановлюємо openresolv з репозиторію..."
        sudo apt install -y openresolv || echo "[!] Не вдалося встановити openresolv"
    fi
else
    echo "[✓] resolvconf вже встановлено."
fi

echo "[✓] Установка WireGuard завершена успішно для $DISTRO $VERSION_ID"
