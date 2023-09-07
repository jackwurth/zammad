### Databse
function database_configure() {
  if [ -n "${DB_CONNECTION}" ]; then
      DB_ADAPTER=$(echo "${DB_CONNECTION}" | cut -d ':' -f 1)
      DB_USER=$(echo "${DB_CONNECTION}" | cut -d '/' -f 3 | cut -d ':' -f 1)
      DB_PASS=$(echo "${DB_CONNECTION}" | cut -d '/' -f 3 | cut -d ':' -f 2 | cut -d '@' -f 1)
      DB_HOST=$(echo "${DB_CONNECTION}" | cut -d '@' -f 2 | cut -d ':' -f 1)
      DB_PORT=$(echo "${DB_CONNECTION}" | cut -d '@' -f 2 | cut -d ':' -f 2 | cut -d '/' -f 1)
      DB=$(echo "${DB_CONNECTION}" | cut -d '/' -f 4)
  fi

  echo "# Updating database.yml"
  sed -e "s/.*adapter:.*/  adapter: ${DB_ADAPTER}/" \
    -e "s/.*username:.*/  username: ${DB_USER}/" \
    -e "s/.*password:.*/  password: ${DB_PASS}/" \
    -e "s/.*host:.*/  host: ${DB_HOST}/" \
    -e "s/.*port:.*/  port: ${DB_PORT}/" \
    -e "s/.*database:.*/  database: ${DB}/" < "${ZAMMAD_DIR}/contrib/packager.io/database.yml.pkgr" > "${ZAMMAD_DIR}/config/database.yml"

  chown zammad:zammad "${ZAMMAD_DIR}/config/database.yml"
}

function database_initialize() {
  zammad run rake db:migrate
  zammad run rake db:seed
}

function database_update() {
  zammad run rake db:migrate
}

### Redis
function redis_set_url() {
  zammad config:set REDIS_URL="${REDIS_URL}"
}

function redis_get_url() {
  zammad config:get REDIS_URL
}

### Elasticsearch
function elasticsearch_get_url() {
  zammad run rails r "puts '',Setting.get('es_url')"| tail -n 1 2>> /dev/null
}

function elasticsearch_configure() {
  if [ -z "${ES_URL}" ]; then
    return 0
  fi

  ES_HTTP_TYPE=$(echo "${ES_URL}" | cut -d ':' -f 1)
  if [[ "${ES_URL}" =~ "@" ]]; then
    ES_USER=$(echo "${ES_URL}" | cut -d '/' -f 3 | cut -d ':' -f 1)
    ES_PASS=$(echo "${ES_URL}" | cut -d '/' -f 3 | cut -d ':' -f 2 | cut -d '@' -f 1)
    ES_HOST=$(echo "${ES_URL}" | cut -d '@' -f 2 | cut -d ':' -f 1)
    ES_PORT=$(echo "${ES_URL}" | cut -d '@' -f 2 | cut -d ':' -f 2 | cut -d '/' -f 1)
  else
    ES_USER=""
    ES_PASS=""
    ES_HOST=$(echo "${ES_URL}" | cut -d ':' -f 2 | cut -d '/' -f 3)
    ES_PORT=$(echo "${ES_URL}" | cut -d ':' -f 3 | cut -d '/' -f 1)
  fi

 zammad run rails r "Setting.set('es_url', '${ES_HTTP_TYPE}://${ES_HOST}:${ES_PORT}')"
  if [ -n "${ES_USER}" ]; then
    zammad run rails r "Setting.set('es_user', '${ES_USER}')"
    zammad run rails r "Setting.set('es_password', '${ES_PASS}')"
  fi
}

function elasticsearch_searchindex_rebuild () {
  if [ "${REBUILD_ES_SEARCHINDEX}" == "yes" ]; then
    nohup zammad run rake zammad:searchindex:rebuild &> "${ZAMMAD_DIR}/log/searchindex-rebuild.log" &
  fi
}

### Common
function i18n_update () {
  zammad run rails r 'Locale.sync'
  zammad run rails r 'Translation.sync'
}

function zammad_packages_detect () {
  ZAMMAD_PACKAGES="no"
  if [ "$(zammad run rails r 'puts Package.count.positive?')" == "true" ] && [ -n "$(which yarn 2> /dev/null)" ] ; then
    ZAMMAD_PACKAGES="yes"
  fi

  export ZAMMAD_PACKAGES
}

function create_initscripts () {
  zammad scale web="${ZAMMAD_WEBS}" websocket="${ZAMMAD_WEBSOCKETS}" worker="${ZAMMAD_WORKERS}"

  ${INIT_CMD} enable zammad
}

function set_env_vars () {
  zammad config:set RUBY_MALLOC_ARENA_MAX="${ZAMMAD_RUBY_MALLOC_ARENA_MAX:=2}"
  zammad config:set RUBY_GC_MALLOC_LIMIT="${ZAMMAD_RUBY_GC_MALLOC_LIMIT:=1077216}"
  zammad config:set RUBY_GC_MALLOC_LIMIT_MAX="${ZAMMAD_RUBY_GC_MALLOC_LIMIT_MAX:=2177216}"
  zammad config:set RUBY_GC_OLDMALLOC_LIMIT="${ZAMMAD_RUBY_GC_OLDMALLOC_LIMIT:=2177216}"
  zammad config:set RUBY_GC_OLDMALLOC_LIMIT_MAX="${ZAMMAD_RUBY_GC_OLDMALLOC_LIMIT_MAX:=3000100}"
  if [[ "$(zammad config:get RAILS_LOG_TO_STDOUT)" == "enabled" ]];then
    echo 'Setting default Logging to file, set via "zammad config:set RAILS_LOG_TO_STDOUT=true" if you want to log to STDOUT!'
    zammad config:set RAILS_LOG_TO_STDOUT=
  fi
}

function detect_local_gemfiles () {
  if ls "${ZAMMAD_DIR}"/Gemfile.local* 1> /dev/null 2>&1; then
    zammad config:set BUNDLE_DEPLOYMENT=0
    zammad run bundle config set --local deployment 'false'
    zammad run bundle install
  fi
}

function zammad_packages_reinstall_all () {
  detect_zammad_packages

  if [ "${ZAMMAD_PACKAGES}" == "yes" ]; then
    zammad run rake zammad:package:reinstall_all
    detect_local_gemfiles
    zammad run rake zammad:package:migrate
    zammad run rake assets:precompile
  fi
}

function update_or_install () {
  create_initscripts
  ${INIT_CMD} stop zammad

  if [ "${DB_UPDATE}" == "yes" ]; then

    zammad run rails r Rails.cache.clear
    database_update
    i18n_update
    zammad_packages_reinstall_all
  else
    REBUILD_ES_SEARCHINDEX="yes"

    database_configure
    database_initialize
  fi

  elasticsearch_configure

  elasticsearch_searchindex_rebuild

  echo "# Enforcing 0600 on database.yml ..."
  chmod 600 "${ZAMMAD_DIR}/config/database.yml"

  set_env_vars
  ${INIT_CMD} start zammad
}

