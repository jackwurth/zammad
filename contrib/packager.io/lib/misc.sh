function detect_os() {
  . /etc/os-release

  if [ "${ID}" == "debian" ] || [ "${ID}" == "ubuntu" ]; then
    OS="DEBIAN"
  elif [ "${ID}" == "centos" ] || [ "${ID}" == "fedora" ] || [ "${ID}" == "rhel" ]; then
    OS="REDHAT"
  elif [[ "${ID}" =~ suse|sles ]]; then
    OS="SUSE"
  else
    OS="UNKNOWN"
  fi

  DISTRI="${ID}-${VERSION_ID%%.*}"

  export OS DISTRI
}

function detect_initcmd() {
  if [ -n "$(which systemctl 2> /dev/null)" ]; then
    INIT_CMD="systemctl"
  elif [ -n "$(which initctl 2> /dev/null)" ]; then
    INIT_CMD="initctl"
  else
    function sysvinit() {
      service $2 $1
    }
    INIT_CMD="sysvinit"
  fi

  if [ "${DOCKER}" == "yes" ]; then
    INIT_CMD="initctl"
  fi

  if [ "${DEBUG}" == "yes" ]; then
    echo "INIT CMD = ${INIT_CMD}"
  fi

  export INIT_CMD
}

function detect_service_install() {
  ZAMMAD_SERVICE_INSTALL="no"
  DB_INSTALL="no"
  DB_UPDATE="no"
  PROXY_INSTALL="no"
  REDIS_INSTALL="no"
  ES_INSTALL="yes"

  if [ ! -f "${ZAMMAD_DIR}/config/database.yml" ]; then
    DB_INSTALL="yes"
    ZAMMAD_SERVICE_INSTALL="yes"
  else
    DB_UPDATE="yes"
    ES_INSTALL="no"
  fi

  if [ -z "$(zammad config:get REDIS_URL)" ]; then
    REDIS_INSTALL="yes"
    ZAMMAD_SERVICE_INSTALL="yes"
  fi

  source "${ZAMMAD_DIR}/contrib/packager.io/service/proxy/script.sh"
  proxy_server_detect

  if [ -z "${PROXY_SERVER}" ] || [ ! -f "${PROXY_SERVER_CONF}" ]; then
    PROXY_INSTALL="yes"
    ZAMMAD_SERVICE_INSTALL="yes"
  fi

  export REDIS_INSTALL DB_INSTALL DB_UPDATE PROXY_INSTALL ES_INSTALL ZAMMAD_SERVICE_INSTALL
}
