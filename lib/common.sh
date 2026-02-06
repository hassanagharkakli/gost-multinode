#!/usr/bin/env bash

###############################################################################
# gost-multinode - common helpers
# Author / Maintainer: HassanAgh
###############################################################################

# NOTE:
# This file is intended to be sourced by other scripts. Do NOT enable
# "set -euo pipefail" here, it must be enabled in the main executable script.

GOSTMN_BASE_DIR="/opt/gost-multinode"
GOSTMN_CONFIG_DIR_IRAN="${GOSTMN_BASE_DIR}/config"
GOSTMN_CONFIG_DIR_FOREIGN="${GOSTMN_BASE_DIR}/config/foreign"
GOSTMN_LOG_DIR="${GOSTMN_BASE_DIR}/logs"

pause() {
  read -rp "Press ENTER to continue..." _
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "[!] This command must be run as root." >&2
    exit 1
  fi
}

install_gost() {
  echo "[+] Installing or updating Gost..."
  bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install
  pause
}

validate_port() {
  local port="$1"
  if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
    echo "[!] Invalid port: ${port}. Use a value between 1 and 65535." >&2
    return 1
  fi
}

validate_name() {
  local name="$1"
  # Allow simple host-style names: letters, digits, dash and underscore.
  if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "[!] Invalid name: ${name}. Only letters, digits, '-' and '_' are allowed." >&2
    return 1
  fi
}

validate_ip_or_host() {
  local host="$1"
  # Basic sanity check – accept IP or hostname characters.
  if ! [[ "$host" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "[!] Invalid host or IP: ${host}." >&2
    return 1
  fi
}

status() {
  echo "== Iran node status =="
  systemctl status gost-iran.service --no-pager || echo "gost-iran.service is not active."
  echo
  echo "== Foreign nodes status =="
  systemctl list-units 'gost-foreign@*.service' --no-pager || true
  pause
}

ensure_directories() {
  mkdir -p "${GOSTMN_CONFIG_DIR_FOREIGN}" "${GOSTMN_LOG_DIR}"
  chmod 700 "${GOSTMN_CONFIG_DIR_IRAN}" "${GOSTMN_CONFIG_DIR_FOREIGN}" "${GOSTMN_LOG_DIR}" 2>/dev/null || true
}

uninstall_gost_multinode() {
  require_root

  echo "== gost-multinode uninstall =="
  echo "This will stop services, disable them, and remove /opt/gost-multinode and the gost-manager symlink."
  read -rp "Are you sure you want to continue? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    pause
    return 0
  }

  systemctl stop gost-iran.service 2>/dev/null || true
  systemctl stop 'gost-foreign@*.service' 2>/dev/null || true

  systemctl disable gost-iran.service 2>/dev/null || true
  systemctl disable 'gost-foreign@*.service' 2>/dev/null || true

  rm -f /usr/bin/gost-manager
  rm -rf "${GOSTMN_BASE_DIR}"

  echo "[+] gost-multinode has been removed."
  pause
}

source "${GOSTMN_BASE_DIR}/lib/iran.sh"
source "${GOSTMN_BASE_DIR}/lib/foreign.sh"
