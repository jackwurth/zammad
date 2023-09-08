source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/proxy/script.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/proxy/ui.sh

function proxy_run() {
  if [ "${PROXY_INSTALL}" == "no" ]; then
    return 0
  fi

  proxy_server_detect
  proxy_server_install
  proxy_server_setup

  proxy_ui
}
