SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function proxy_ui_text() {
cat <<EOF
Add your fully qualified domain name or public IP to servername directive of ${PROXY_SERVER}, if this installation is done on a remote server. You have to change: ${PROXY_SERVER_CONF} and restart ${PROXY_SERVER} process. Furthermore you have to set the correct HTTP type and full qualified domain name in Zammad, see https://admin-docs.zammad.org/en/latest/settings/system/base.html

Otherwise just open http://localhost/ in your browser to start using Zammad.
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
