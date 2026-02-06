#!/usr/bin/env bash

###############################################################################
# gost-multinode - interactive manager
# Author / Maintainer: HassanAgh
###############################################################################

set -euo pipefail

GOSTMN_BASE="/opt/gost-multinode"

if [[ ! -d "${GOSTMN_BASE}/lib" ]]; then
  echo "[!] gost-multinode base directory not found at ${GOSTMN_BASE}." >&2
  echo "    Please run the installer again or adjust GOSTMN_BASE." >&2
  exit 1
fi

# shellcheck source=/opt/gost-multinode/lib/common.sh
source "${GOSTMN_BASE}/lib/common.sh"

require_root
ensure_directories

while true; do
  clear
  echo "==== Gost MultiNode Manager (by HassanAgh) ===="
  echo
  echo "Iran node:"
  echo "  1) Install / update Gost binary"
  echo "  2) Configure Iran relay node"
  echo "  3) Start / restart Iran relay service"
  echo
  echo "Foreign nodes (multiple instances supported):"
  echo "  4) Add or update a foreign node configuration"
  echo "  5) Start / restart all foreign node services"
  echo
  echo "Maintenance:"
  echo "  6) Show service status"
  echo "  7) Uninstall gost-multinode (manager and services)"
  echo
  echo "  0) Exit"
  echo
  read -rp "Select an option: " c

  case "$c" in
    1) install_gost ;;
    2) setup_iran ;;
    3) start_iran ;;
    4) add_foreign ;;
    5) start_foreign ;;
    6) status ;;
    7) uninstall_gost_multinode ;;
    0) exit 0 ;;
    *) echo "[!] Invalid choice."; pause ;;
  esac
done
