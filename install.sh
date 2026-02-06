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

# GitHub repository base URL for raw content
REPO_URL="https://raw.githubusercontent.com/hassanagharkakli/gost-multinode/main"

# Download main manager script
echo "[+] Downloading gost-manager.sh..."
curl -fsSL "${REPO_URL}/gost-manager.sh" -o "${BASE_DIR}/gost-manager.sh"

# Download library scripts
echo "[+] Downloading library scripts..."
curl -fsSL "${REPO_URL}/lib/common.sh" -o "${BASE_DIR}/lib/common.sh"
curl -fsSL "${REPO_URL}/lib/iran.sh" -o "${BASE_DIR}/lib/iran.sh"
curl -fsSL "${REPO_URL}/lib/foreign.sh" -o "${BASE_DIR}/lib/foreign.sh"

# Download systemd service files
echo "[+] Downloading systemd service files..."
curl -fsSL "${REPO_URL}/systemd/gost-iran.service" -o "${BASE_DIR}/systemd/gost-iran.service"
curl -fsSL "${REPO_URL}/systemd/gost-foreign@.service" -o "${BASE_DIR}/systemd/gost-foreign@.service"

# Install systemd service files to system directory
echo "[+] Installing systemd service files..."
cp "${BASE_DIR}/systemd/gost-iran.service" /etc/systemd/system/
cp "${BASE_DIR}/systemd/gost-foreign@.service" /etc/systemd/system/
systemctl daemon-reload

chmod +x "${BASE_DIR}/gost-manager.sh"
chmod 644 /etc/systemd/system/gost-iran.service /etc/systemd/system/gost-foreign@.service
chmod 700 "${BASE_DIR}/config" "${BASE_DIR}/config/foreign" "${BASE_DIR}/logs" 2>/dev/null || true

ln -sf "${BASE_DIR}/gost-manager.sh" /usr/bin/gost-manager

echo
echo "[+] Installation completed successfully."
echo "[i] Run 'gost-manager' as root to configure Iran and foreign nodes."
