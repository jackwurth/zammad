function elasticsearch_server_install() {
  case ${OS} in
    DEBIAN)
      curl --silent --location https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
        gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
      apt-get install apt-transport-https
      echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | \
        tee /etc/apt/sources.list.d/elastic-8.x.list
      apt-get update
      apt-get install elasticsearch
      ;;
    REDHAT)
      rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
      elasticsearch_rpm_repo > /etc/yum.repos.d/elasticsearch.repo
      yum install -y --enablerepo=elasticsearch elasticsearch
      ;;
    SUSE)
      rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
      elasticsearch_rpm_repo > /etc/zypp/repos.d/elasticsearch.repo
      zypper modifyrepo --enable elasticsearch
      zypper install -y elasticsearch
      zypper modifyrepo --disable elasticsearch
      ;;
    *)
      echo "OS not supported"
      return 1
      ;;
  esac
}

function elasticsearch_server_setup() {
  chown root:elasticsearch /etc/elasticsearch/certs

  ${INIT_CMD} enable elasticsearch
  ${INIT_CMD} restart elasticsearch

  ES_PASSWORD=$(/usr/share/elasticsearch/bin/elasticsearch-reset-password --username elastic --silent --batch)
  ES_URL="https://elastic:${ES_PASSWORD}@localhost:9200"

  export ES_URL
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
