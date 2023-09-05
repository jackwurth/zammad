SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function ui_welcome_text() {
cat <<EOF
Welcome to Zammad!

This script will guide you through the installation of Zammad.

Please note that this script will install and configure all required services on the local machine.
If you want to use existing, non-default or remote services, please make sure to have the following relevant information ready:

 * Database (PostgreSQL, MySQL/MariaDB) connection details
 * Redis connection details
 * Elasticsearch connection details
 * Proxy connection details (full qualified domain name, optional SSL certificate)

If you are unsure about any of these, please choose the local setup.
For more information, please refer to the documentation at https://docs.zammad.org.

Continue with local setup? If in doubt, choose yes.
EOF
}

function ui_welcome() {
  if [ "${ZAMMAD_UPDATE}" == "yes" ]; then
    return 0
  fi

  LOCAL_ONLY="no"
  whiptail \
    --title "Zammad Setup" \
    --yesno "$(ui_welcome_text)" \
    $((LINES - 10)) $((COLUMNS - 10)) && LOCAL_ONLY="yes"

  export LOCAL_ONLY
}
