#!/bin/bash
#
# packager.io preinstall script
#

ZAMMAD_DIR=${ZAMMAD_DIR:="/opt/zammad"}
export ZAMMAD_DIR

source ${ZAMMAD_DIR}/contrib/packager.io/lib/service/database/script.sh

#
# Make sure that after installation/update there can be only one sprockets manifest,
#   the one coming from the package. The package manager will ignore any duplicate files
#   which might come from a backup restore and/or a manual 'assets:precompile' command run.
#   These duplicates can cause the application to fail, however.
#
rm -f ${ZAMMAD_DIR}/public/assets/.sprockets-manifest-*.json || true

# Ensure database connectivity
if [[ -f /opt/zammad/config/database.yml ]]; then
  if databse_server_verify_connection; then
     echo "!!! ERROR !!!"
     echo "Your database does not seem to be online!"
     echo "Please check your configuration in config/database.yml and ensure the configured database server is online."
     echo "Exiting Zammad package installation / upgrade - try again."

     exit 1
  fi
fi

# remove local files of the packages
if type -P zammad >/dev/null; then
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
fi
