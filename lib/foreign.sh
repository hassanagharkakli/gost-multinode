DIR="/opt/gost-multinode/config/foreign"

add_foreign() {
  ensure_directories

  echo
  echo "=========================================="
  echo "  Add Foreign Node Configuration"
  echo "=========================================="
  echo

  local name iran_ip iran_port user auth_mode pass key_file cfg

  while :; do
    read -rp "Foreign node name (used as systemd instance name): " name
    if [[ -z "$name" ]]; then
      echo "[!] Name cannot be empty." >&2
      continue
    fi
    if validate_name "$name"; then
      break
    fi
  done

  while :; do
    read -rp "Iran relay IP / hostname: " iran_ip
    if validate_ip_or_host "$iran_ip"; then
      break
    fi
  done

  while :; do
    read -rp "Iran relay port: " iran_port
    if validate_port "$iran_port"; then
      break
    fi
  done

  read -rp "Relay username (must match Iran node configuration): " user
  if [[ -z "$user" ]]; then
    echo "[!] Username cannot be empty." >&2
    return 1
  fi

  echo "Authentication mode to Iran relay:"
  echo "  1) Password"
  echo "  2) SSH private key"
  read -rp "Choose authentication mode [1/2]: " auth_mode

  case "$auth_mode" in
    2)
      read -rp "Path to SSH private key (on foreign node): " key_file
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

  cfg="${DIR}/${name}.conf"

  {
    echo "NAME=${name}"
    echo "IRAN=${iran_ip}"
    echo "PORT=${iran_port}"
    echo "USER=${user}"
    if [[ "$auth_mode" == "2" ]]; then
      echo "AUTH_MODE=key"
      echo "KEY_FILE=${key_file}"
    else
      echo "AUTH_MODE=password"
      echo "PASS=${pass}"
    fi
  } > "${cfg}"

  # At least one mapping is required.
  while :; do
    local local_port remote_port yn

    while :; do
      read -rp "Local port to expose on this foreign node: " local_port
      if validate_port "$local_port"; then
        break
      fi
    done

    while :; do
      read -rp "Destination port on Iran side (relay will forward to this port): " remote_port
      if validate_port "$remote_port"; then
        break
      fi
    done

    echo "MAP=${local_port}:${remote_port}" >> "${cfg}"

    read -rp "Add another port mapping? [y/N]: " yn
    if [[ ! "$yn" =~ ^[Yy]$ ]]; then
      break
    fi
  done

  chmod 600 "${cfg}"

  echo
  echo "[+] Foreign node configuration saved successfully!"
  echo "    Configuration file: ${cfg}"
  echo "    Node name: ${name}"
  echo
  echo "[i] Next step: Use option 5 to start all foreign node services."
  pause
}

start_foreign() {
  ensure_directories

  echo
  echo "=========================================="
  echo "  Starting Foreign Node Services"
  echo "=========================================="
  echo

  local f name count=0
  shopt -s nullglob

  # Check if any configs exist
  if ! ls "${DIR}"/*.conf >/dev/null 2>&1; then
    echo "[!] No foreign node configurations found."
    echo "    Please add a foreign node configuration first (option 4)."
    shopt -u nullglob
    pause
    return 1
  fi

  echo "[+] Reloading systemd daemon..."
  systemctl daemon-reload

  echo "[+] Processing foreign node configurations..."
  for f in "${DIR}"/*.conf; do
    name=$(basename "$f" .conf)
    echo "  - Enabling gost-foreign@${name}.service..."
    systemctl enable "gost-foreign@${name}.service" 2>/dev/null || true
    echo "  - Starting gost-foreign@${name}.service..."
    if systemctl restart "gost-foreign@${name}.service"; then
      ((count++))
    else
      echo "    [!] Failed to start gost-foreign@${name}.service"
    fi
  done
  shopt -u nullglob

  echo
  if [[ $count -gt 0 ]]; then
    echo "[+] Started ${count} foreign node service(s)."
    echo "[i] Use option 6 to check service status."
  else
    echo "[!] No services were started successfully."
    echo "[i] Check logs with: journalctl -u 'gost-foreign@*.service' -n 50"
  fi
  pause
}
