IRAN_CONF="/opt/gost-multinode/config/iran.conf"

setup_iran() {
  ensure_directories

  echo
  echo "=========================================="
  echo "  Configure Iran Relay Node"
  echo "=========================================="
  echo

  local port user auth_mode pass key_file allowlist

  while :; do
    read -rp "Relay port (listening port on Iran node): " port
    if validate_port "$port"; then
      break
    fi
  done

  read -rp "Relay username: " user
  if [[ -z "$user" ]]; then
    echo "[!] Username cannot be empty." >&2
    return 1
  fi

  echo "Authentication mode:"
  echo "  1) Password"
  echo "  2) SSH private key"
  read -rp "Choose authentication mode [1/2]: " auth_mode

  case "$auth_mode" in
    2)
      read -rp "Path to SSH private key (on Iran node): " key_file
      if [[ -z "$key_file" ]]; then
        echo "[!] Key path cannot be empty." >&2
        return 1
      fi
      ;;
    *)
      auth_mode=1
      read -rsp "Relay password: " pass
      echo
      if [[ -z "$pass" ]]; then
        echo "[!] Password cannot be empty." >&2
        return 1
      fi
      ;;
  esac

  echo
  echo "Optional: IP allowlist for incoming SSH connections to the relay."
  echo "You can enter a comma-separated list of IPs or CIDR ranges (for example: 1.2.3.4,10.0.0.0/8)."
  echo "Leave empty to allow all IPs (recommended only behind a firewall)."
  read -rp "IP/CIDR allowlist (optional): " allowlist

  {
    echo "PORT=${port}"
    echo "USER=${user}"
    if [[ "$auth_mode" == "2" ]]; then
      echo "AUTH_MODE=key"
      echo "KEY_FILE=${key_file}"
    else
      echo "AUTH_MODE=password"
      echo "PASS=${pass}"
    fi
    if [[ -n "$allowlist" ]]; then
      echo "ALLOWLIST=${allowlist}"
    fi
  } > "${IRAN_CONF}"

  chmod 600 "${IRAN_CONF}"

  echo
  echo "[+] Iran relay configuration saved successfully!"
  echo "    Configuration file: ${IRAN_CONF}"
  echo
  echo "[i] Important: Make sure to open port ${port} on your firewall."
  echo "[i] Next step: Use option 3 to start the Iran relay service."
  pause
}

start_iran() {
  if [[ ! -f "${IRAN_CONF}" ]]; then
    echo
    echo "[!] Error: Iran relay configuration not found."
    echo "    Please configure the Iran node first (option 2)."
    pause
    return 1
  fi

  echo
  echo "=========================================="
  echo "  Starting Iran Relay Service"
  echo "=========================================="
  echo

  echo "[+] Reloading systemd daemon..."
  systemctl daemon-reload

  echo "[+] Enabling gost-iran.service..."
  systemctl enable gost-iran.service

  echo "[+] Starting gost-iran.service..."
  if systemctl restart gost-iran.service; then
    sleep 1
    if systemctl is-active --quiet gost-iran.service; then
      echo
      echo "[+] Iran relay service started successfully!"
      echo "[i] Use option 6 to check service status."
    else
      echo
      echo "[!] Service started but may not be running correctly."
      echo "[i] Check status with: systemctl status gost-iran.service"
    fi
  else
    echo
    echo "[!] Failed to start gost-iran.service"
    echo "[i] Check logs with: journalctl -u gost-iran.service -n 50"
  fi
  pause
}
