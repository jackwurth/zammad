#!/bin/bash
#
# packager.io postinstall script
#

# base dir
ZAMMAD_DIR=${ZAMMAD_DIR:="/opt/zammad"}
export ZAMMAD_DIR

# import config
source ${ZAMMAD_DIR}/contrib/packager.io/config

PATH="${ZAMMAD_DIR}/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"

source ${ZAMMAD_DIR}/contrib/packager.io/lib/misc.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/zammad.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/proxy/script.sh

SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function ui_prompt_text() {
cat <<EOF
Welcome to Zammad!

To finalize the installation or update, please run the following script with root privileges:

  ${ZAMMAD_DIR}/script/zammad-install.sh

The script will guide you through the installation of required services and the final Zammad application setup.
EOF
}

function ui_prompt() {
  whiptail \
    --title "Zammad Setup" \
    --msgbox "$(ui_prompt_text)" \
    $((LINES - 10)) $((COLUMNS - 10))
}

detect_os

detect_initcmd

detect_service_install

if [ "${ZAMMAD_SERVICE_INSTALL}" == "no" ]; then
  update_or_install

  proxy_server_detect
  proxy_server_setup

  exit 0
fi

ui_prompt

exit 0
