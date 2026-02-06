install_gost() {
  bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install
  pause
}

pause() { read -rp "Enter..."; }

status() {
  systemctl status gost-iran --no-pager
  systemctl list-units 'gost-foreign*'
  pause
}

source /opt/gost-multinode/lib/iran.sh
source /opt/gost-multinode/lib/foreign.sh
