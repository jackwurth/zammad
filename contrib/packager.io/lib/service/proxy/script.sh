function proxy_server_detect() {
  PROXY_SERVER=""
  PROXY_SERVER_CONF=""

  case "${OS}" in
    DEBIAN)
      if dpkg --status nginx >/dev/null 2>&1; then
        PROXY_SERVER="nginx"
        PROXY_SERVER_CONF="/etc/nginx/sites-available/zammad.conf"
      elif dpkg --status apache2 >/dev/null 2>&1; then
        PROXY_SERVER="apache2"
        PROXY_SERVER_CONF="/etc/apache2/sites-available/zammad.conf"
      fi
      ;;
    REDHAT)
      if rpm -query nginx >/dev/null 2>&1; then
        PROXY_SERVER="nginx"
        PROXY_SERVER_CONF="/etc/nginx/conf.d/zammad.conf"
      elif rpm -query httpd >/dev/null 2>&1; then
        PROXY_SERVER="apache2"
        PROXY_SERVER_CONF="/etc/httpd/conf.d/zammad.conf"
      fi
      ;;
    SUSE)
      if rpm -query nginx >/dev/null 2>&1; then
        PROXY_SERVER="nginx"
        PROXY_SERVER_CONF="/etc/nginx/vhosts.d/zammad.conf"
      elif rpm -query apache2 >/dev/null 2>&1; then
        PROXY_SERVER="apache2"
        PROXY_SERVER_CONF="/etc/apache2/vhosts.d/zammad.conf"
      fi
      ;;
  esac

  export PROXY_SERVER
  export PROXY_SERVER_CONF
}

function proxy_server_install() {
  if [ -n "${PROXY_SERVER}" ]; then
    return 0
  fi

  case "${OS}" in
    DEBIAN)
      apt-get update
      apt-get install --yes nginx
      ;;
    REDHAT)
      yum updateinfo
      yum install --assumeyes nginx
      ;;
    SUSE)
      zypper refresh
      zypper --non-interactive install nginx
      ;;
  esac

  proxy_server_detect
}

function proxy_server_setup() {
  # Determine contrib proxy server config
  CONTRIB_PROXY_CONF_DIR="${ZAMMAD_DIR}/contrib/nginx"
  if [ "${PROXY_SERVER}" == "apache2" ]; then
    CONTRIB_PROXY_CONF_DIR="${ZAMMAD_DIR}/contrib/apache2"
  fi
  CONTRIB_PROXY_CONF_FILE="zammad.conf"
  CONTRIB_PROXY_CONF="${CONTRIB_PROXY_CONF_DIR}/${CONTRIB_PROXY_CONF_FILE}"

  # Copy contrib proxy server config
  if [ -e "${PROXY_SERVER_CONF}" ]; then
    cp "${CONTRIB_PROXY_CONF}" "${PROXY_SERVER_CONF}.dpkg-$(date +%Y%m%d%H%M%S)"
    return 0
  fi

  cp "${CONTRIB_PROXY_CONF}" "${PROXY_SERVER_CONF}"

  if [ "${PROXY_SERVER}" == "nginx" ]; then
    ln -s ${PROXY_SERVER_CONF} /etc/${PROXY_SERVER}/sites-enabled/zammad.conf
  elif [ "${PROXY_SERVER}" == "apache2" ]; then
    a2enmod proxy
    a2enmod proxy_http
    a2enmod proxy_wstunnel
    a2ensite zammad.conf
  fi
}
