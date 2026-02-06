#!/usr/bin/env bash

###############################################################################
# gost-multinode - installer
# Author / Maintainer: HassanAgh
###############################################################################

set -euo pipefail

BASE_DIR="/opt/gost-multinode"
readonly REPO_URL="https://raw.githubusercontent.com/hassanagharkakli/gost-multinode/main"

###############################################################################
# Privilege handling: auto-elevate with sudo if needed
###############################################################################

check_and_elevate() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    echo "[→] Not running as root. Attempting to elevate privileges with sudo..."
    exec sudo "$0" "$@"
  else
    echo
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   Error: Root privileges required                ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo
    echo "[!] This installer must be run with root privileges."
    echo
    echo "[i] Options:"
    echo "    1. Run as root user: sudo $0"
    echo "    2. Run with sudo: sudo bash $0"
    echo "    3. Switch to root: su -"
    echo
    exit 1
  fi
}

check_and_elevate "$@"

###############################################################################
# Status display helpers
###############################################################################

show_status() {
  local item="$1"
  local status="$2"
  case "$status" in
    check)
      if [[ -e "$item" ]] || command -v "$item" >/dev/null 2>&1; then
        echo "[✔] $item - already installed"
        return 0
      else
        echo "[✖] $item - not installed"
        return 1
      fi
      ;;
    installing)
      echo "[→] $item - installing..."
      ;;
    success)
      echo "[✔] $item - installation successful"
      ;;
    failed)
      echo "[✖] $item - installation failed"
      return 1
      ;;
  esac
}

verify_file() {
  local file="$1"
  if [[ -f "$file" ]] && [[ -s "$file" ]]; then
    return 0
  else
    return 1
  fi
}

verify_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# Installation steps
###############################################################################

install_dependencies() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Step 1: Installing system dependencies         ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] This step installs required packages: curl, wget, nano, ca-certificates"
  echo

  export DEBIAN_FRONTEND=noninteractive
  if apt-get update -y && apt-get install -y curl wget nano ca-certificates; then
    echo
    show_status "System dependencies" "success"
    return 0
  else
    echo
    show_status "System dependencies" "failed"
    return 1
  fi
}

install_gost_binary() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Step 2: Checking Gost binary                    ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Gost is the core relay software required for this setup."
  echo

  if verify_command "gost"; then
    echo "[✔] Gost binary - already installed"
    echo "[i] Gost is already installed. Skipping binary installation."
    return 0
  fi

  show_status "Gost binary" "installing"
  if bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install; then
    sleep 1
    if verify_command "gost"; then
      show_status "Gost binary" "success"
      return 0
    else
      show_status "Gost binary" "failed"
      return 1
    fi
  else
    show_status "Gost binary" "failed"
    return 1
  fi
}

create_directories() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Step 3: Creating directory structure           ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Setting up directories for configuration files and logs."
  echo

  show_status "Directory structure" "installing"
  if mkdir -p \
    "${BASE_DIR}/lib" \
    "${BASE_DIR}/config" \
    "${BASE_DIR}/config/foreign" \
    "${BASE_DIR}/logs"; then
    chmod 700 "${BASE_DIR}" "${BASE_DIR}/config" "${BASE_DIR}/config/foreign" "${BASE_DIR}/logs" 2>/dev/null || true
    if [[ -d "${BASE_DIR}/lib" ]] && [[ -d "${BASE_DIR}/config" ]] && [[ -d "${BASE_DIR}/logs" ]]; then
      show_status "Directory structure" "success"
      return 0
    else
      show_status "Directory structure" "failed"
      return 1
    fi
  else
    show_status "Directory structure" "failed"
    return 1
  fi
}

download_manager_files() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Step 4: Downloading manager files               ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Downloading the management interface and library files."
  echo

  local failed=0

  show_status "gost-manager.sh" "installing"
  local url="${REPO_URL}/gost-manager.sh"
  if curl -fsSL "$url" -o "${BASE_DIR}/gost-manager.sh"; then
    if verify_file "${BASE_DIR}/gost-manager.sh"; then
      chmod +x "${BASE_DIR}/gost-manager.sh"
      show_status "gost-manager.sh" "success"
    else
      show_status "gost-manager.sh" "failed"
      ((failed++))
    fi
  else
    show_status "gost-manager.sh" "failed"
    ((failed++))
  fi

  show_status "lib/common.sh" "installing"
  local url="${REPO_URL}/lib/common.sh"
  if curl -fsSL "$url" -o "${BASE_DIR}/lib/common.sh"; then
    if verify_file "${BASE_DIR}/lib/common.sh"; then
      show_status "lib/common.sh" "success"
    else
      show_status "lib/common.sh" "failed"
      ((failed++))
    fi
  else
    show_status "lib/common.sh" "failed"
    ((failed++))
  fi

  show_status "lib/iran.sh" "installing"
  local url="${REPO_URL}/lib/iran.sh"
  if curl -fsSL "$url" -o "${BASE_DIR}/lib/iran.sh"; then
    if verify_file "${BASE_DIR}/lib/iran.sh"; then
      show_status "lib/iran.sh" "success"
    else
      show_status "lib/iran.sh" "failed"
      ((failed++))
    fi
  else
    show_status "lib/iran.sh" "failed"
    ((failed++))
  fi

  show_status "lib/foreign.sh" "installing"
  local url="${REPO_URL}/lib/foreign.sh"
  if curl -fsSL "$url" -o "${BASE_DIR}/lib/foreign.sh"; then
    if verify_file "${BASE_DIR}/lib/foreign.sh"; then
      show_status "lib/foreign.sh" "success"
    else
      show_status "lib/foreign.sh" "failed"
      ((failed++))
    fi
  else
    show_status "lib/foreign.sh" "failed"
    ((failed++))
  fi

  if [[ $failed -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

install_systemd_services() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Step 5: Installing systemd service files        ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Installing systemd service units for automatic service management."
  echo

  local failed=0

  show_status "gost-iran.service" "installing"
  local url="${REPO_URL}/systemd/gost-iran.service"
  if curl -fsSL "$url" -o /etc/systemd/system/gost-iran.service; then
    if verify_file /etc/systemd/system/gost-iran.service; then
      chmod 644 /etc/systemd/system/gost-iran.service
      show_status "gost-iran.service" "success"
    else
      show_status "gost-iran.service" "failed"
      ((failed++))
    fi
  else
    show_status "gost-iran.service" "failed"
    ((failed++))
  fi

  show_status "gost-foreign@.service" "installing"
  local url="${REPO_URL}/systemd/gost-foreign@.service"
  if curl -fsSL "$url" -o /etc/systemd/system/gost-foreign@.service; then
    if verify_file /etc/systemd/system/gost-foreign@.service; then
      chmod 644 /etc/systemd/system/gost-foreign@.service
      show_status "gost-foreign@.service" "success"
    else
      show_status "gost-foreign@.service" "failed"
      ((failed++))
    fi
  else
    show_status "gost-foreign@.service" "failed"
    ((failed++))
  fi

  if [[ $failed -eq 0 ]]; then
    show_status "systemd daemon-reload" "installing"
    if systemctl daemon-reload; then
      show_status "systemd daemon-reload" "success"
      return 0
    else
      show_status "systemd daemon-reload" "failed"
      return 1
    fi
  else
    return 1
  fi
}

create_symlink() {
  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Step 6: Creating command symlink               ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] Creating symlink for easy access: gost-manager"
  echo

  show_status "gost-manager symlink" "installing"
  if ln -sf "${BASE_DIR}/gost-manager.sh" /usr/bin/gost-manager; then
    if [[ -L /usr/bin/gost-manager ]] && [[ -x /usr/bin/gost-manager ]]; then
      show_status "gost-manager symlink" "success"
      return 0
    else
      show_status "gost-manager symlink" "failed"
      return 1
    fi
  else
    show_status "gost-manager symlink" "failed"
    return 1
  fi
}

###############################################################################
# Main installation flow
###############################################################################

main() {
  clear
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Gost MultiNode Installer (by HassanAgh)         ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo
  echo "[i] This installer will set up gost-multinode on your system."
  echo "[i] The installation process consists of 6 steps."
  echo
  read -rp "Press ENTER to begin installation, or Ctrl+C to cancel... " _

  local errors=0

  install_dependencies || ((errors++))
  install_gost_binary || ((errors++))
  create_directories || ((errors++))
  download_manager_files || ((errors++))
  install_systemd_services || ((errors++))
  create_symlink || ((errors++))

  echo
  echo "╔════════════════════════════════════════════════════╗"
  echo "║   Installation Summary                            ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo

  if [[ $errors -eq 0 ]]; then
    echo "[✔] Installation completed successfully!"
    echo
    echo "[i] Next steps:"
    echo "    1. Run 'gost-manager' to configure your nodes"
    echo "    2. Configure the Iran relay node (option 2)"
    echo "    3. Configure foreign nodes (option 4)"
    echo
  else
    echo "[✖] Installation completed with $errors error(s)."
    echo
    echo "[!] Please review the errors above and try again."
    echo "[i] You can re-run this installer to fix any issues."
    echo
    exit 1
  fi
}

main "$@"
