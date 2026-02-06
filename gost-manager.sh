#!/usr/bin/env bash

###############################################################################
# gost-multinode - interactive manager
# Author / Maintainer: HassanAgh
###############################################################################

set -euo pipefail

GOSTMN_BASE="/opt/gost-multinode"

###############################################################################
# Privilege handling: auto-elevate with sudo if needed
###############################################################################

check_and_elevate() {
  local current_uid
  current_uid=$(id -u 2>/dev/null || echo "unknown")

  if [[ ${EUID:-$current_uid} -eq 0 ]]; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    echo "[→] Not running as root (UID: ${current_uid}). Attempting to elevate privileges with sudo..."
    echo "[i] You may be prompted for your password."
    exec sudo "$0" "$@"
  else
    echo
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   Error: Root privileges required                ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo
    echo "[!] This manager must be run with root privileges."
    echo "[!] Current UID: ${current_uid}"
    echo
    echo "[i] Options:"
    echo "    1. Run with sudo: sudo gost-manager"
    echo "    2. Run with sudo bash: sudo bash /opt/gost-multinode/gost-manager.sh"
    echo "    3. Switch to root: su -"
    echo
    exit 1
  fi
}

check_and_elevate "$@"

###############################################################################
# Initialization and validation
###############################################################################

if [[ ! -d "${GOSTMN_BASE}/lib" ]]; then
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Error: gost-multinode not installed             ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[!] Base directory not found: ${GOSTMN_BASE}"
  echo
  echo "[i] Please install gost-multinode first:"
  echo "    curl -fsSL https://raw.githubusercontent.com/hassanagharkakli/gost-multinode/main/install.sh | bash"
  echo
  exit 1
fi

# shellcheck source=/opt/gost-multinode/lib/common.sh
source "${GOSTMN_BASE}/lib/common.sh"

ensure_directories

###############################################################################
# Menu navigation system
###############################################################################

MENU_STACK=()

push_menu() {
  MENU_STACK+=("$1")
}

pop_menu() {
  if [[ ${#MENU_STACK[@]} -gt 0 ]]; then
    unset 'MENU_STACK[-1]'
  fi
}

get_current_menu() {
  if [[ ${#MENU_STACK[@]} -gt 0 ]]; then
    echo "${MENU_STACK[-1]}"
  else
    echo "main"
  fi
}

###############################################################################
# Menu screens
###############################################################################

show_main_menu() {
  clear
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Gost MultiNode Manager (by HassanAgh)          ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Main menu - Select an option to manage your nodes"
  echo
  echo "  1) Iran Node Management"
  echo "  2) Foreign Node Management"
  echo "  3) Service Status & Monitoring"
  echo "  4) System Maintenance"
  echo
  echo "  0) Exit"
  echo
  read -rp "  Select an option: " choice

  case "$choice" in
    1) push_menu "main"; show_iran_menu ;;
    2) push_menu "main"; show_foreign_menu ;;
    3) push_menu "main"; show_status_menu ;;
    4) push_menu "main"; show_maintenance_menu ;;
    0) 
      echo
      echo "[i] Exiting gost-multinode manager..."
      exit 0 
      ;;
    *) 
      echo
      echo "[!] Invalid choice. Please select a valid option."
      sleep 1
      show_main_menu
      ;;
  esac
}

show_iran_menu() {
  clear
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Iran Node Management                             ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] The Iran node acts as a central relay for foreign nodes."
  echo "[i] Configure it first, then connect foreign nodes to it."
  echo
  echo "  1) Install / Update Gost Binary"
  echo "  2) Configure Iran Relay Node"
  echo "  3) Start / Restart Iran Relay Service"
  echo
  echo "  0) Back to Main Menu"
  echo
  read -rp "  Select an option: " choice

  case "$choice" in
    1) install_gost; show_iran_menu ;;
    2) setup_iran; show_iran_menu ;;
    3) start_iran; show_iran_menu ;;
    0) pop_menu; show_main_menu ;;
    *) 
      echo
      echo "[!] Invalid choice. Please select a valid option."
      sleep 1
      show_iran_menu
      ;;
  esac
}

show_foreign_menu() {
  clear
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Foreign Node Management                          ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Foreign nodes connect to your Iran relay from outside."
  echo "[i] You can configure multiple foreign nodes on this system."
  echo
  echo "  1) Add or Update Foreign Node Configuration"
  echo "  2) Start / Restart All Foreign Node Services"
  echo "  3) List Configured Foreign Nodes"
  echo
  echo "  0) Back to Main Menu"
  echo
  read -rp "  Select an option: " choice

  case "$choice" in
    1) add_foreign; show_foreign_menu ;;
    2) start_foreign; show_foreign_menu ;;
    3) list_foreign_nodes; show_foreign_menu ;;
    0) pop_menu; show_main_menu ;;
    *) 
      echo
      echo "[!] Invalid choice. Please select a valid option."
      sleep 1
      show_foreign_menu
      ;;
  esac
}

show_status_menu() {
  clear
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Service Status & Monitoring                      ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] View the current status of all gost-multinode services."
  echo
  status
  echo
  echo "  0) Back to Main Menu"
  echo
  read -rp "  Press ENTER to refresh status, or 0 to go back: " choice
  case "$choice" in
    0) pop_menu; show_main_menu ;;
    *) show_status_menu ;;
  esac
}

show_maintenance_menu() {
  clear
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   System Maintenance                               ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Maintenance and system management options."
  echo
  echo "  1) Uninstall gost-multinode"
  echo "  2) Verify Installation"
  echo
  echo "  0) Back to Main Menu"
  echo
  read -rp "  Select an option: " choice

  case "$choice" in
    1) 
      uninstall_gost_multinode
      if [[ ! -d "${GOSTMN_BASE}/lib" ]]; then
        echo
        echo "[i] gost-multinode has been uninstalled. Exiting..."
        exit 0
      fi
      show_maintenance_menu
      ;;
    2) verify_installation; show_maintenance_menu ;;
    0) pop_menu; show_main_menu ;;
    *) 
      echo
      echo "[!] Invalid choice. Please select a valid option."
      sleep 1
      show_maintenance_menu
      ;;
  esac
}

###############################################################################
# Additional helper functions
###############################################################################

list_foreign_nodes() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Configured Foreign Nodes                        ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo

  local count=0
  shopt -s nullglob
  for f in "${GOSTMN_CONFIG_DIR_FOREIGN}"/*.conf; do
    local name
    name=$(basename "$f" .conf)
    local status_text
    if systemctl is-active --quiet "gost-foreign@${name}.service" 2>/dev/null; then
      status_text="[✔] Active"
    else
      status_text="[✖] Inactive"
    fi
    echo "  ${name}: ${status_text}"
    ((count++))
  done
  shopt -u nullglob

  if [[ $count -eq 0 ]]; then
    echo "[i] No foreign node configurations found."
    echo "[i] Use option 1 to add a foreign node configuration."
  else
    echo
    echo "[i] Found ${count} foreign node configuration(s)."
  fi
  pause
}

verify_installation() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Installation Verification                        ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Checking installation components..."
  echo

  local all_ok=true

  if command -v gost >/dev/null 2>&1; then
    echo "[✔] Gost binary is installed"
  else
    echo "[✖] Gost binary is NOT installed"
    all_ok=false
  fi

  if [[ -f "${GOSTMN_BASE}/gost-manager.sh" ]]; then
    echo "[✔] Manager script exists"
  else
    echo "[✖] Manager script is missing"
    all_ok=false
  fi

  if [[ -f "${GOSTMN_BASE}/lib/common.sh" ]] && \
     [[ -f "${GOSTMN_BASE}/lib/iran.sh" ]] && \
     [[ -f "${GOSTMN_BASE}/lib/foreign.sh" ]]; then
    echo "[✔] Library files exist"
  else
    echo "[✖] Some library files are missing"
    all_ok=false
  fi

  if [[ -f /etc/systemd/system/gost-iran.service ]] && \
     [[ -f /etc/systemd/system/gost-foreign@.service ]]; then
    echo "[✔] Systemd service files exist"
  else
    echo "[✖] Systemd service files are missing"
    all_ok=false
  fi

  if [[ -L /usr/bin/gost-manager ]] && [[ -x /usr/bin/gost-manager ]]; then
    echo "[✔] Command symlink exists and is executable"
  else
    echo "[✖] Command symlink is missing or not executable"
    all_ok=false
  fi

  echo
  if [[ "$all_ok" == "true" ]]; then
    echo "[✔] All components verified successfully!"
  else
    echo "[✖] Some components are missing or incorrect."
    echo "[i] Please re-run the installer to fix issues."
  fi
  pause
}

###############################################################################
# Main entry point
###############################################################################

main() {
  push_menu "main"
  while true; do
    case "$(get_current_menu)" in
      main) show_main_menu ;;
      *) show_main_menu ;;
    esac
  done
}

main "$@"
