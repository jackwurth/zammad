SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function elasticsearch_ui_text_local_custom() {
cat <<EOF
Please choose to set up a local Elasticsearch service or use an existing one.

If you are unsure, choose local setup.
EOF
}

function elasticsearch_ui_local_custom() {
  whiptail \
    --title "Zammad Setup" \
    --yesno "$(elasticsearch_ui_text_local_custom)" \
    --yes-button "Local Setup" \
    --no-button "Custom Setup" \
    $((LINES - 10)) $((COLUMNS - 10))
}
