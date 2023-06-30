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

function detect_update() {
  DB_UPDATE="no"
  REDIS_UPDATE="no"
  PROXY_UPDATE="no"
  ZAMMAD_UPDATE="no"

  if [ -f "${ZAMMAD_DIR}/config/database.yml" ]; then
    DB_UPDATE="yes"
    PROXY_UPDATE="yes"

    ZAMMAD_UPDATE="yes"
  fi

  if [ -z "$(zammad config:get REDIS_URL)" ]; then
    REDIS_UPDATE="yes"
  fi

  export DB_UPDATE REDIS_UPDATE ES_UPDATE PROXY_UPDATE ZAMMAD_UPDATE
}
