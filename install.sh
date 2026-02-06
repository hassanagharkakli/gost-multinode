#!/usr/bin/env bash

###############################################################################
# gost-multinode - installer
# Author / Maintainer: HassanAgh
###############################################################################

set -euo pipefail

BASE_DIR="/opt/gost-multinode"
REPO_URL="https://raw.githubusercontent.com/hassanagharkakli/gost-multinode/main"

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

echo "[+] Creating directory structure..."
mkdir -p \
  "${BASE_DIR}/lib" \
  "${BASE_DIR}/config" \
  "${BASE_DIR}/config/foreign" \
  "${BASE_DIR}/logs"

# Set restrictive permissions on config and logs directories
chmod 700 "${BASE_DIR}" "${BASE_DIR}/config" "${BASE_DIR}/config/foreign" "${BASE_DIR}/logs" 2>/dev/null || true

echo "[+] Downloading gost-multinode files..."

curl -fsSL "${REPO_URL}/gost-manager.sh" -o "${BASE_DIR}/gost-manager.sh"

curl -fsSL "${REPO_URL}/lib/common.sh"  -o "${BASE_DIR}/lib/common.sh"
curl -fsSL "${REPO_URL}/lib/iran.sh"    -o "${BASE_DIR}/lib/iran.sh"
curl -fsSL "${REPO_URL}/lib/foreign.sh" -o "${BASE_DIR}/lib/foreign.sh"

echo "[+] Installing systemd service files..."

curl -fsSL "${REPO_URL}/systemd/gost-iran.service" \
  -o /etc/systemd/system/gost-iran.service

curl -fsSL "${REPO_URL}/systemd/gost-foreign@.service" \
  -o /etc/systemd/system/gost-foreign@.service

chmod 644 /etc/systemd/system/gost-iran.service \
          /etc/systemd/system/gost-foreign@.service

chmod +x "${BASE_DIR}/gost-manager.sh"

systemctl daemon-reload

ln -sf "${BASE_DIR}/gost-manager.sh" /usr/bin/gost-manager

echo
echo "[+] Installation completed successfully."
echo "[i] Run 'gost-manager' as root to configure Iran and foreign nodes."
