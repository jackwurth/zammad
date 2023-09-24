SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function database_ui_text_custom() {
cat <<EOF
Please provide a database connection string.

postgresql|mysql2://user:password@host:port/database

Beware that the user needs to have full access to the database.
We strongly recommend to use a PostgreSQL database.
EOF
}

function database_ui_custom() {
  DB_URL=$(whiptail \
    --title "Zammad Setup" \
    --inputbox "$(database_ui_text_custom)" \
    $((LINES - 10)) $((COLUMNS - 10)) \
    postgresql://zammad:zammad@localhost:5432/zammad \
    3>&1 1>&2 2>&3
  ) || DB_URL=""

  export DB_URL
}
