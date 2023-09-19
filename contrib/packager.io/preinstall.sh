#!/bin/bash
#
# packager.io preinstall script
#

ZAMMAD_DIR=${ZAMMAD_DIR:="/opt/zammad"}
export ZAMMAD_DIR

function database_server_verify_connection_script() {
  cat <<EOF
require 'active_record'
require 'yaml'

exit(1) if ! File.exist?('${ZAMMAD_DIR}/config/database.yml')

db_config = YAML.load_file('${ZAMMAD_DIR}/config/database.yml', aliases: true)['production']

begin
  ActiveRecord::Base.establish_connection(db_config)
  ActiveRecord::Base.connection
rescue StandardError
  # noop
end

ActiveRecord::Base.connected? ? exit(0) : exit(1)
EOF
}


# Ensure database connectivity
function database_server_verify_connection() {
  if [[ ! -f /opt/zammad/config/database.yml ]]; then
    return 0
  fi

  database_server_verify_connection_script > ${ZAMMAD_DIR}/tmp/database_server_verify_connection.rb
  zammad run ruby ${ZAMMAD_DIR}/tmp/database_server_verify_connection.rb
  rc=$?
  rm -f ${ZAMMAD_DIR}/tmp/database_server_verify_connection.rb

  if [[ $rc -ne 0 ]]; then
     echo "!!! ERROR !!!"
     echo "Your database does not seem to be online!"
     echo "Please check your configuration in config/database.yml and ensure the configured database server is online."
     echo "Exiting Zammad package installation / upgrade - try again."

     exit 1
  fi
}

#
# Make sure that after installation/update there can be only one sprockets manifest,
#   the one coming from the package. The package manager will ignore any duplicate files
#   which might come from a backup restore and/or a manual 'assets:precompile' command run.
#   These duplicates can cause the application to fail, however.
#
function clean_sprockets_manifest() {
  rm -f ${ZAMMAD_DIR}/public/assets/.sprockets-manifest-*.json || true
}

# remove local files of the packages
function remove_local_package_files() {
  if ! type -P zammad >/dev/null; then
    return 0
  fi

  PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

  RAKE_TASKS=$(zammad run rake --tasks | grep "zammad:package:uninstall_all_files")

  if [[ x$RAKE_TASKS == 'x' ]]; then
     echo "# Code does not yet fit, skipping automatic package uninstall."
     echo "... This is not an error and will work during your next upgrade ..."
     exit 0
  fi

  if [ "$(zammad run rails r 'puts Package.count.positive?')" == "true" ] && type -P yarn >/dev/null && type -P node >/dev/null; then
     echo "# Detected custom packages..."
     echo "# Remove custom packages files temporarily..."
     zammad run rake zammad:package:uninstall_all_files
  fi
}

function main() {
  database_server_verify_connection
  clean_sprockets_manifest
  remove_local_package_files
}

main ${1+"$@"}
