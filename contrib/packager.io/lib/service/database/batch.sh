source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/database/script.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/database/ui.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/database/ui/custom.sh

function database_run() {
  if [ "${DB_UPDATE}" == "yes" ]; then
    return 0
  fi

  if [ "${LOCAL_ONLY}" == "no" ]; then
    database_ui_local_custom || \
      database_ui_custom
  fi

  if [ -z "$DB_CONNECTION" ]; then
      database_server_install
      database_server_setup
  fi
}
