#!/usr/bin/env bash

set -e
set -u

BASISKAART_DB_HOST=${BASISKAART_DB_HOST:-basiskaart-read.service.consul}
BASISKAART_DB_PORT=${BASISKAART_DB_PORT:-5432}
BASISKAART_DB_NAME=${BASISKAART_DB_NAME:-basiskaart}
BASISKAART_DB_USER=${BASISKAART_DB_USER:-${BASISKAART_DB_NAME}}
BASISKAART_DB_PASSWORD=${BASISKAART_DB_PASSWORD:-insecure}

echo Creating configuration files
touch /srv/mapserver/connection_basiskaart.inc

cat > /srv/mapserver/connection_basiskaart.inc <<EOF
CONNECTIONTYPE postgis
CONNECTION "host=${BASISKAART_DB_HOST} dbname=${BASISKAART_DB_NAME} user=${BASISKAART_DB_USER} password=${BASISKAART_DB_PASSWORD} port=${BASISKAART_DB_PORT}"
PROCESSING "CLOSE_CONNECTION=DEFER"
EOF

# Configure apache to redirect errors to stderr.
# The mapserver will redirect errors to apache errorstream (see header.inc and private/header.inc)
# and apache will then redirect this to stderr, which will then be redirected to syslog/kibana.
# ref: http://mapserver.org/optimization/debugging.html#steps-to-enable-mapserver-debugging
#      https://serverfault.com/questions/711168/writing-apache2-logs-to-stdout-stderr
sed -i 's/ErrorLog .*/ErrorLog \/dev\/stderr/' /etc/apache2/apache2.conf

# Replace actual location of the mapserver depending on the environment
sed -i 's#MAP_URL_REPLACE#'"$MAP_URL"'#g' /srv/mapserver/topografie.map /srv/mapserver/topografie_wm.map

echo Starting server
apachectl -D FOREGROUND

