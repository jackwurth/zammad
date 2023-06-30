SIZE=$(stty size)
LINES=${SIZE% *}
COLUMNS=${SIZE#* }

function elasticsearch_ui_text_custom() {
cat <<EOF
Please provide a Elasticsearch connection string.

http[s]://[user:password@]host:port

Please get sure to install the 'ingest-attachment' plugin on your Elasticsearch server beforehand version 8 by:

    $ /usr/share/elasticsearch/bin/elasticsearch-plugin -s install ingest-attachment

After this you might need to rebuild the searchindex by:

    $ zammad run rake zammad:searchindex:rebuild"
EOF
}

function elasticsearch_ui_custom() {
  ES_URL=$(whiptail \
    --title "Zammad Setup" \
    --inputbox "$(elasticsearch_ui_text_custom)" \
    $((LINES - 10)) $((COLUMNS - 10)) \
    https://elastic:elastic@localhost:9200 \
    3>&1 1>&2 2>&3
  ) || ES_URL=""

  export ES_URL
}
