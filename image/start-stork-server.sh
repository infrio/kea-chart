#!/bin/bash

set -o errexit
set -a

. /etc/stork/server.env

wait_for_psql(){
  until nc -vz $STORK_DATABASE_HOST $STORK_DATABASE_PORT > /dev/null; do
    echo "$STORK_DATABASE_HOST:$STORK_DATABASE_PORT is unavailable - sleeping"
    sleep 3
  done
  echo "$STORK_DATABASE_HOST:$STORK_DATABASE_PORT is up"

  until PGPASSWORD=$STORK_DATABASE_PASSWORD psql -h $STORK_DATABASE_HOST -U $STORK_DATABASE_USER_NAME -d $STORK_DATABASE_NAME -c "select * from gopg_migrations" > /dev/null; do
    echo "Stork database is not ready, keep waiting"
    sleep 3
  done
}

wait_for_psql
echo "Stork database is ready"

# /usr/bin/stork-tool cert-export --db-user $STORK_DATABASE_USER_NAME --db-password $STORK_DATABASE_PASSWORD --db-host $STORK_DATABASE_HOST --db-name $STORK_DATABASE_NAME --object cacert  --file /etc/stork/certs/ca.pem
# /usr/bin/stork-tool cert-export --db-user $STORK_DATABASE_USER_NAME --db-password $STORK_DATABASE_PASSWORD --db-host $STORK_DATABASE_HOST --db-name $STORK_DATABASE_NAME --object srvcert  --file /etc/stork/certs/server.pem
# /usr/bin/stork-tool cert-export --db-user $STORK_DATABASE_USER_NAME --db-password $STORK_DATABASE_PASSWORD --db-host $STORK_DATABASE_HOST --db-name $STORK_DATABASE_NAME --object srvkey  --file /etc/stork/certs/server.key

# STORK_REST_TLS_CERTIFICATE=/etc/stork/certs/server.pem
# STORK_REST_TLS_PRIVATE_KEY=/etc/stork/certs/server.key
# STORK_REST_TLS_CA_CERTIFICATE=/etc/stork/certs/ca.pem

/usr/bin/stork-server
