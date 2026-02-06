#!/usr/bin/env bash

###############################################################################
# gost-multinode - installer
# Author / Maintainer: HassanAgh
###############################################################################

set -euo pipefail

BASE_DIR="/opt/gost-multinode"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "[!] This installer must be run as root." >&2
  exit 1
fi

echo "== Gost MultiNode Installer (by HassanAgh) =="

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl wget nano ca-certificates

if ! command -v gost >/dev/null 2>&1; then
  echo "[+] Installing Gost binary..."
  bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install
else
  echo "[i] Gost is already installed. Skipping binary installation."
fi

mkdir -p "${BASE_DIR}/lib" "${BASE_DIR}/config/foreign" "${BASE_DIR}/logs" "${BASE_DIR}/systemd"

echo "[+] Installing gost-multinode manager files..."
cp gost-manager.sh "${BASE_DIR}/"
cp lib/*.sh "${BASE_DIR}/lib/"
cp systemd/*.service "${BASE_DIR}/systemd/"

chmod +x "${BASE_DIR}/gost-manager.sh"
chmod 700 "${BASE_DIR}/config" "${BASE_DIR}/config/foreign" "${BASE_DIR}/logs" 2>/dev/null || true

ln -sf "${BASE_DIR}/gost-manager.sh" /usr/bin/gost-manager

echo
echo "[+] Installation completed successfully."
echo "[i] Run 'gost-manager' as root to configure Iran and foreign nodes."
