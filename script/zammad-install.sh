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

# import functions
source ${ZAMMAD_DIR}/contrib/packager.io/lib/misc.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/ui.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/database/batch.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/redis/batch.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/elasticsearch/batch.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/proxy/batch.sh
source ${ZAMMAD_DIR}/contrib/packager.io/lib/zammad.sh

function detect_update() {
  DB_UPDATE="no"
  REDIS_UPDATE="no"
  PROXY_UPDATE="no"
  ZAMMAD_UPDATE="no"

  export DB_UPDATE REDIS_UPDATE PROXY_UPDATE ZAMMAD_UPDATE
}

# exec postinstall
detect_os

detect_initcmd

detect_update

ui_welcome

database_run

redis_run

elasticsearch_run

proxy_run

update_or_install
