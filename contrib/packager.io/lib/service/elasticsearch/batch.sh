source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/elasticsearch/script.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/elasticsearch/ui.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/elasticsearch/ui/custom.sh

function elasticsearch_run() {
  if [ "${ES_INSTALL}" == "no" ]; then
    return 0
  fi

  if [ "${LOCAL_ONLY}" == "no" ]; then
    elasticsearch_ui_local_custom || \
      elasticsearch_ui_custom
  fi

  if [ "${ES_URL}" == "SKIP" ]; then
    ES_URL=""
    export ES_URL

    return 0
  fi

  if [ -z "$ES_URL" ]; then
      elasticsearch_server_install
      elasticsearch_server_setup
  fi
}
