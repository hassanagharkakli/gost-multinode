IRAN_CONF="/opt/gost-multinode/config/iran.conf"

setup_iran() {
  read -rp "پورت Relay: " PORT
  read -rp "یوزر: " USER
  read -rsp "پسورد: " PASS; echo

  cat > $IRAN_CONF <<EOF
PORT=$PORT
USER=$USER
PASS=$PASS
EOF

  echo "✔ ذخیره شد"
  pause
}

start_iran() {
  systemctl enable gost-iran
  systemctl restart gost-iran
  pause
}
