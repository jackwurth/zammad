source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/proxy/script.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/proxy/ui.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/proxy/ui/custom.sh

function proxy_run() {
  proxy_server_detect
  proxy_server_install
  proxy_server_setup

  proxy_ui
}
