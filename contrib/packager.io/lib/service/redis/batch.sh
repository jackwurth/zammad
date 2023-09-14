source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/redis/script.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/redis/ui.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/redis/ui/custom.sh

function redis_run() {
  if [ "${REDIS_INSTALL}" == "no" ]; then
    return 0
  fi

  if [ "${LOCAL_ONLY}" == "no" ]; then
    redis_ui_local_custom || \
      redis_ui_custom
  fi

  if [ -z "${REDIS_URL}" ]; then
      redis_server_install
      redis_server_setup
  fi
}
