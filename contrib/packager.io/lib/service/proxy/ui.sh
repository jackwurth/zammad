SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function proxy_ui_text() {
cat <<EOF
You have to change ${PROXY_SERVER_CONF} by setting the server name directive to the FQDN of your Zammad installation and provide a SSL certificate and key in the directory described in the related directives. If you don't have a SSL certificate you can use the following command to create a self-signed certificate:

    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout example.com-key.pem -out example.com-crt.pem

or use Let's Encrypt (https://letsencrypt.org) to create a trusted certificate. You have to enable the ${PROXY_SERVER} configuration and restart the ${PROXY_SERVER} service afterwards. Furthermore you have to set the correct HTTP type and full qualified domain name in Zammad, see https://admin-docs.zammad.org/en/latest/settings/system/base.html

For ${PROXY_SERVER} configuration without SSL support see ${ZAMMAD_DIR}/contrib/${PROXY_SERVER}.

Locally you can open http://localhost:3000/ in your browser to start using Zammad.
EOF

  case "${OS}" in
      REDHAT)
cat <<EOF

Remember to enable selinux and firewall rules!

Use the following commands:
    $ setsebool httpd_can_network_connect on -P
    $ firewall-cmd --zone=public --add-service=http --permanent
    $ firewall-cmd --zone=public --add-service=https --permanent
    $ firewall-cmd --reload
EOF
      ;;
      SUSE)
cat <<EOF

Make sure that the firewall is not blocking port 80 & 443!

Use 'yast firewall' or 'SuSEfirewall2' commands to configure it.
EOF
      ;;
  esac
}

function proxy_ui() {
  whiptail \
    --title "Zammad Setup" \
    --msgbox "$(proxy_ui_text)" \
    $((LINES - 10)) $((COLUMNS - 10))
}
