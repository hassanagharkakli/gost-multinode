DIR="/opt/gost-multinode/config/foreign"

add_foreign() {
  read -rp "اسم نود: " NAME
  read -rp "IP ایران: " IP
  read -rp "پورت ایران: " PORT
  read -rp "یوزر: " USER
  read -rsp "پسورد: " PASS; echo

  CFG="$DIR/$NAME.conf"
  echo "IRAN=$IP" > $CFG
  echo "PORT=$PORT" >> $CFG
  echo "USER=$USER" >> $CFG
  echo "PASS=$PASS" >> $CFG

  while true; do
    read -rp "پورت لوکال: " L
    read -rp "پورت مقصد: " R
    echo "MAP=$L:$R" >> $CFG
    read -rp "پورت دیگه؟ (y/n): " yn
    [[ $yn != y ]] && break
  done
}

start_foreign() {
  for f in $DIR/*.conf; do
    name=$(basename $f .conf)
    systemctl enable gost-foreign@$name
    systemctl restart gost-foreign@$name
  done
  pause
}
