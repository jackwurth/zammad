function database_server_install() {
  case ${OS} in
    DEBIAN)
      apt-get update
      apt-get install -y postgresql
      ;;
    REDHAT)
      yum updateinfo
      yum install -y postgresql-server
      su - postgres -c 'install -d -m 700 /var/lib/pgsql/data'
      su - postgres -c '/usr/bin/initdb --auth=peer --auth-host=scram-sha-256 --pgdata=/var/lib/pgsql/data --locale=C.UTF-8 --encoding=utf8'
      ;;
    SUSE)
      zypper refresh
      zypper install -y postgresql-server
      su - postgres -c 'install -d -m 700 /var/lib/pgsql/data'
      su - postgres -c '/usr/bin/initdb --auth=peer --auth-host=scram-sha-256 --pgdata=/var/lib/pgsql/data --locale=C.UTF-8 --encoding=utf8'
      ;;
  esac
}

function database_server_setup() {
  ${INIT_CMD} enable postgresql.service
  ${INIT_CMD} restart postgresql.service

  DB_PASS="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 10)"
  echo "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';" | su - postgres -c psql
  su - postgres -c "createdb -E UTF8 ${DB} -O ${DB_USER}"
  echo "GRANT ALL PRIVILEGES ON DATABASE \"${DB}\" TO \"${DB_USER}\";" | su - postgres -c psql

  DB_ADAPTER="postgresql"
  DB_HOST="localhost"
  DB_PORT="5432"

  export DB_PASS DB_ADAPTER DB_HOST DB_PORT DB_USER DB
}

function database_server_verify_connection_script() {
  cat <<EOF
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'active_record'
require 'yaml'

exit(1) if ! File.exist?('${ZAMMAD_DIR}/config/database.yml')

YAML.load_file('${ZAMMAD_DIR}/config/database.yml', aliases: true)['production']

begin
  ActiveRecord::Base.establish_connection(db_config)
  ActiveRecord::Base.connection
rescue StandardError
  # noop
end

ActiveRecord::Base.connected? ? exit(0) : exit(1)
EOF
}

function database_server_verify_connection() {
    zammad run ruby -e "$(database_server_verify_connection_script)"
}
