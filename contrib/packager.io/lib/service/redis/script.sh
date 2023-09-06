function redis_server_install() {
  case ${OS} in
    DEBIAN)
      apt-get update
      apt-get install -y redis-server redis-tools
      ;;
    REDHAT)
      if [ "${DISTRI}" == "centos-7" ]; then
        echo "Custom setup only"
      else
        yum updateinfo
        yum install -y redis
      fi
      ;;
    SUSE)
      echo "Custom setup only"
      ;;
  esac
}

function redis_server_setup() {
  case ${OS} in
    DEBIAN)
      # ${INIT_CMD} enable redis-server
      # ${INIT_CMD} restart redis-server
      ;;
    REDHAT)
      ${INIT_CMD} enable redis
      ${INIT_CMD} restart redis
      ;;
    SUSE)
      if [ ! -e /etc/redis/default.conf ]; then
        cp -a /etc/redis/default.conf.example /etc/redis/default.conf
      fi
      install -d -o redis -g redis -m 0750 /var/lib/redis/default
      ${INIT_CMD} enable redis@default
      ${INIT_CMD} restart redis@default
      ;;
  esac

  REDIS_URL="redis://localhost:6379"
  export REDIS_URL
}
