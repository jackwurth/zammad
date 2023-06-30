SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function redis_ui_text_custom() {
cat <<EOF
Please provide a redis connection string.

redis://[[user]:password@]host:port[/db-number]
EOF
}

function redis_ui_custom() {
  REDIS_URL=$(whiptail \
    --title "Zammad Setup" \
    --inputbox "$(redis_ui_text_custom)" \
    $((LINES - 10)) $((COLUMNS - 10)) \
    redis://localhost:6379 \
    3>&1 1>&2 2>&3
  ) || REDIS_URL=""

  export REDIS_URL
}
