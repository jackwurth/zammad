function database_server_install() {
  case ${OS} in
    DEBIAN)
      apt-get update
      apt-get install -y postgresql
      ;;
    REDHAT)
      if [ "${DISTRI}" == "centos-7" ]; then
        yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
        yum install -y postgresql15-server
        /usr/pgsql-15/bin/postgresql-15-setup initdb
      else
        yum updateinfo
        yum install -y postgresql-server
        su - postgres -c 'postgresql-setup --initdb --unit postgresql'
      fi
      ;;
    SUSE)
      zypper refresh
      zypper install -y postgresql-server
      ;;
  esac
}

function database_server_pre_setup() {
  if [[ "${OS}" != "REDHAT" ]]; then
    return 0
  fi

  sed -i 's/ident/scram-sha-256/g' /var/lib/pgsql/data/pg_hba.conf
  echo "password_encryption = scram-sha-256" >> /var/lib/pgsql/data/postgresql.conf
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
