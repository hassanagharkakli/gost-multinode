#!/usr/bin/env bash
BASE="/opt/gost-multinode"
source $BASE/lib/common.sh

while true; do
  clear
  echo "==== Gost MultiNode Manager ===="
  echo "1) نصب / آپدیت Gost"
  echo "2) تنظیم نود ایران"
  echo "3) اجرای نود ایران"
  echo "4) اضافه کردن نود خارج"
  echo "5) اجرای نودهای خارج"
  echo "6) وضعیت سرویس‌ها"
  echo "0) خروج"
  read -rp "انتخاب: " c

  case $c in
    1) install_gost ;;
    2) setup_iran ;;
    3) start_iran ;;
    4) add_foreign ;;
    5) start_foreign ;;
    6) status ;;
    0) exit ;;
  esac
done
