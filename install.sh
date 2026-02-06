#!/usr/bin/env bash
set -e

BASE_DIR="/opt/gost-multinode"

echo "== Gost MultiNode Installer =="

apt update -y
apt install -y curl wget nano

if ! command -v gost >/dev/null; then
  echo "[+] Installing Gost..."
  bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install
fi

mkdir -p $BASE_DIR/{lib,config/foreign,logs,systemd}

echo "[+] Installing manager..."
cp gost-manager.sh $BASE_DIR/
cp lib/*.sh $BASE_DIR/lib/
cp systemd/*.service $BASE_DIR/systemd/

chmod +x $BASE_DIR/gost-manager.sh

ln -sf $BASE_DIR/gost-manager.sh /usr/bin/gost-manager

echo "✔ نصب کامل شد"
echo "👉 اجرا: gost-manager"
