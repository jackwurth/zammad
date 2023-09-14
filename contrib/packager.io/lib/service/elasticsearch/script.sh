function elasticsearch_server_install() {
  case ${OS} in
    DEBIAN)
      apt-get install apt-transport-https
      if [ ! -f /etc/apt/sources.list.d/elastic-8.x.list ]; then
        curl --silent --location https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
          gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | \
          tee /etc/apt/sources.list.d/elastic-8.x.list
      fi
      apt-get update
      apt-get install elasticsearch
      ;;
    REDHAT)
      if [ ! -f /etc/yum.repos.d/elasticsearch.repo ]; then
        rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
        elasticsearch_rpm_repo > /etc/yum.repos.d/elasticsearch.repo
      fi
      yum install -y --enablerepo=elasticsearch elasticsearch
      ;;
    SUSE)
      if [ ! -f /etc/zypp/repos.d/elasticsearch.repo ]; then
        rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
        elasticsearch_rpm_repo > /etc/zypp/repos.d/elasticsearch.repo
        zypper modifyrepo --enable elasticsearch
      fi
      zypper install -y elasticsearch
      ;;
    *)
      echo "OS not supported"
      return 1
      ;;
  esac
}

function elasticsearch_server_setup() {
  chown root:elasticsearch /etc/elasticsearch/certs
  cat << EOF > /etc/elasticsearch/jvm.options.d/zammad.options
-Xms1g
-Xmx2g
EOF
  chown root:elasticsearch /etc/elasticsearch/jvm.options.d/zammad.options

  ${INIT_CMD} enable elasticsearch
  ${INIT_CMD} restart elasticsearch

  ES_PASSWORD=$(/usr/share/elasticsearch/bin/elasticsearch-reset-password --username elastic --silent --batch)
  ES_URL="https://elastic:${ES_PASSWORD}@localhost:9200"
  ES_LOCAL="yes"

  export ES_URL ES_LOCAL
}

function elasticsearch_rpm_repo() {
cat << EOF
[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF
}
