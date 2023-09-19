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
  ${INIT_CMD} start postgresql.service

  DB_PASS="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 10)"
  echo "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';" | su - postgres -c psql
  su - postgres -c "createdb -E UTF8 ${DB} -O ${DB_USER}"
  echo "GRANT ALL PRIVILEGES ON DATABASE \"${DB}\" TO \"${DB_USER}\";" | su - postgres -c psql

  DB_ADAPTER="postgresql"
  DB_HOST="localhost"
  DB_PORT="5432"

  export DB_PASS DB_ADAPTER DB_HOST DB_PORT DB_USER DB
}
