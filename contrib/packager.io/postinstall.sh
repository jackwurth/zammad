#!/bin/bash
#
# packager.io postinstall script
#

# base dir
ZAMMAD_DIR=${ZAMMAD_DIR:="/opt/zammad"}

SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function ui_prompt_text() {
cat <<EOF
Welcome to Zammad!

To finalize the package installation or update, please run the following script with root privileges:

  ${ZAMMAD_DIR}/script/zammad-installer
EOF
}

function ui_prompt() {
  if [ "${ZAMMAD_UPDATE}" == "yes" ]; then
    return 0
  fi

  whiptail \
    --title "Zammad Setup" \
    --msgbox "$(ui_prompt_text)" \
    $((LINES - 10)) $((COLUMNS - 10))
}

ui_prompt
