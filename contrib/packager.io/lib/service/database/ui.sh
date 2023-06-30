SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function database_ui_text_local_custom() {
cat <<EOF
Please choose to set up a local database (PostgreSQL) or use an existing one (PostgreSQL, MySQL/MariaDB).

If you are unsure, choose local setup.
EOF
}

function database_ui_local_custom() {
  whiptail \
    --title "Zammad Setup" \
    --yesno "$(database_ui_text_local_custom)" \
    --yes-button "Local Setup" \
    --no-button "Custom Setup" \
    $((LINES - 10)) $((COLUMNS - 10))
}
