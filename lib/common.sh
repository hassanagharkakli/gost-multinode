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
  echo
  read -rp "Press ENTER to continue... " _
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "[!] This command must be run as root." >&2
    return 1
  fi
}

install_gost() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Install / Update Gost Binary                    ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Gost is the core relay software required for this setup."
  echo

  if command -v gost >/dev/null 2>&1; then
    echo "[✔] Gost binary is already installed."
    echo "[i] Current version: $(gost -V 2>&1 | head -n1 || echo 'unknown')"
    echo
    read -rp "Do you want to update Gost? [y/N]: " update_choice
    if [[ ! "$update_choice" =~ ^[Yy]$ ]]; then
      echo "[i] Update cancelled."
      pause
      return 0
    fi
  fi

  echo "[→] Installing / updating Gost binary..."
  echo
  if bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install; then
    sleep 1
    if command -v gost >/dev/null 2>&1; then
      echo
      echo "[✔] Gost installation completed successfully!"
      echo "[i] Installed version: $(gost -V 2>&1 | head -n1 || echo 'unknown')"
    else
      echo
      echo "[✖] Gost installation may have failed. Please verify manually."
    fi
  else
    echo
    echo "[✖] Gost installation failed. Please check your internet connection and try again."
  fi
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
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Service Status Overview                          ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "--- Iran Node Status ---"
  if systemctl is-active --quiet gost-iran.service 2>/dev/null; then
    echo "[✔] gost-iran.service is active"
    echo
    systemctl status gost-iran.service --no-pager -l --lines=10 || true
  elif systemctl is-enabled --quiet gost-iran.service 2>/dev/null; then
    echo "[✖] gost-iran.service is enabled but not running"
    echo "[i] Check logs: journalctl -u gost-iran.service -n 20"
  else
    echo "[✖] gost-iran.service is not configured or not enabled"
  fi
  echo
  echo "--- Foreign Nodes Status ---"
  local count
  count=$(systemctl list-units 'gost-foreign@*.service' --no-pager --no-legend 2>/dev/null | wc -l)
  if [[ $count -gt 0 ]]; then
    echo "[i] Found ${count} foreign node service(s):"
    echo
    systemctl list-units 'gost-foreign@*.service' --no-pager || true
  else
    echo "[i] No foreign node services are currently active."
    echo "[i] Configure foreign nodes from the Foreign Node Management menu."
  fi
  echo
  pause
}

ensure_directories() {
  mkdir -p "${GOSTMN_CONFIG_DIR_FOREIGN}" "${GOSTMN_LOG_DIR}"
  chmod 700 "${GOSTMN_CONFIG_DIR_IRAN}" "${GOSTMN_CONFIG_DIR_FOREIGN}" "${GOSTMN_LOG_DIR}" 2>/dev/null || true
}

uninstall_gost_multinode() {
  if ! require_root; then
    return 1
  fi

  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Uninstall gost-multinode                         ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "WARNING: This operation will permanently remove:"
  echo "  - All gost-multinode services (stopped and disabled)"
  echo "  - Configuration files in /opt/gost-multinode"
  echo "  - Manager script and libraries"
  echo "  - Command symlink (/usr/bin/gost-manager)"
  echo
  echo "Note: The Gost binary itself will NOT be removed."
  echo
  read -rp "Are you absolutely sure you want to continue? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo
    echo "[i] Uninstall cancelled."
    pause
    return 0
  fi

  echo
  echo "[→] Stopping services..."
  systemctl stop gost-iran.service 2>/dev/null || true
  systemctl stop 'gost-foreign@*.service' 2>/dev/null || true
  sleep 1

  echo "[→] Disabling services..."
  systemctl disable gost-iran.service 2>/dev/null || true
  systemctl disable 'gost-foreign@*.service' 2>/dev/null || true

  echo "[→] Removing files..."
  rm -f /usr/bin/gost-manager
  rm -rf "${GOSTMN_BASE_DIR}"

  # Verify removal
  if [[ ! -d "${GOSTMN_BASE_DIR}" ]] && [[ ! -L /usr/bin/gost-manager ]]; then
    echo
    echo "[✔] gost-multinode has been successfully removed."
  else
    echo
    echo "[✖] Some files may not have been removed completely."
    echo "[i] Please check manually: ${GOSTMN_BASE_DIR}"
  fi
  pause
}

source "${GOSTMN_BASE_DIR}/lib/iran.sh"
source "${GOSTMN_BASE_DIR}/lib/foreign.sh"
