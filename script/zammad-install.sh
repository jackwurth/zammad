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

[[ $ZAMMAD_DEBUG == "yes" ]] && set -x

# exec service installation
detect_os

detect_initcmd

detect_service_install

if [ "${ZAMMAD_SERVICE_INSTALL}" == "no" ]; then
  SIZE=$(stty size)
  LINES=${SIZE% *}
  COLUMNS=${SIZE#* }

  whiptail \
    --title "Zammad Setup" \
    --msgbox "No action needed. All services are set up." \
    $((LINES - 10)) $((COLUMNS - 10))

  set +x
  exit 0
fi

ui_welcome

database_run

redis_run

elasticsearch_run

update_or_install

proxy_run

set +x
