SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function redis_ui_text_deprecated() {
cat <<EOF
Your Linux distribution does not provide a recent Redis package nor are there any third-party repositories available.
For local setup please follow the instructions at https://redis.io/docs/ and rerun the installation. For custom setup please provide a redis connection string on the next step.

If no REDIS_URL is provided, Zammad will not be able to start and the installation is aborted.
EOF
}

function redis_ui_deprecated() {
  whiptail \
    --title "Zammad Setup" \
    --msgbox "$(redis_ui_text_deprecated)" \
    $((LINES - 10)) $((COLUMNS - 10))
}
