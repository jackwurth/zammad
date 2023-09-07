source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/redis/script.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/redis/ui.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/redis/ui/custom.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/redis/ui/deprecated.sh

function redis_run() {
  if [ "${REDIS_INSTALL}" == "no" ]; then
    return 0
  fi

  if [ "${OS}" == "SUSE" ] || [ "${DISTRI}" == "centos-7" ]; then
      redis_ui_deprecated
      redis_ui_custom
      if [ -z "${REDIS_URL}" ]; then
          exit 1
      fi
  elif [ "${LOCAL_ONLY}" == "no" ]; then
    redis_ui_local_custom || \
      redis_ui_custom
  fi

  if [ -z "${REDIS_URL}" ]; then
      redis_server_install
      redis_server_setup
  fi
}
