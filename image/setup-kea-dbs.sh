#!/bin/bash

set -o errexit

if [[ ! -e /etc/kea-db-config/password ]]; then
    echo "db config not found"
    exit 1
fi
PASSWORD=$(cat /etc/kea-db-config/password)
DB_PORT="5432"

wait_for_psql(){
  until PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres --list > /dev/null; do
    echo "$DB_HOST:$DB_PORT is not ready"
    sleep 5
  done
}

set_up_user() {
    db_user=$1
    db_password=$2
    cat <<EOF > /tmp/${db_user}.sql
select 'create user ${db_user} with superuser password null' where not exists (select from pg_user where usename = '${db_user}')
\gexec
alter user ${db_user} with encrypted password '${db_password}'
\gexec
EOF
    PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres -f /tmp/${db_user}.sql
    rm /tmp/${db_user}.sql
}

set_up_database() {
    db_name=$1
    db_user=$2
    cat <<EOF > /tmp/${db_name}.sql
select 'create database ${db_name}' where not exists (select from pg_database where datname = '${db_name}')
\gexec
grant all privileges on database ${db_name} to ${db_user}
\gexec
EOF
    PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres -f /tmp/${db_name}.sql
    rm /tmp/${db_name}.sql
}

wait_for_psql
echo "Database server is ready"

# config db
set_up_user ${CONFIG_DB_USER} ${CONFIG_DB_PASSWORD}
set_up_database ${PRIMARY_CONFIG_DB_NAME} ${CONFIG_DB_USER}
set_up_database ${STANDBY_CONFIG_DB_NAME} ${CONFIG_DB_USER}
# stork db
set_up_user ${STORK_DB_USER} ${STORK_DB_PASSWORD}
set_up_database ${STORK_DB_NAME} ${STORK_DB_USER}

echo "Databases created"

# init tables for config database
kea-admin db-init pgsql -u postgres -h $DB_HOST -p $PASSWORD -n ${PRIMARY_CONFIG_DB_NAME}
kea-admin db-init pgsql -u postgres -h $DB_HOST -p $PASSWORD -n ${STANDBY_CONFIG_DB_NAME}
echo "Config database initialized"

# init stork database
stork-tool db-init --db-user ${STORK_DB_USER} --db-password ${STORK_DB_PASSWORD} --db-host $DB_HOST --db-name ${STORK_DB_NAME}
stork-tool db-up --db-user ${STORK_DB_USER} --db-password ${STORK_DB_PASSWORD} --db-host $DB_HOST --db-name ${STORK_DB_NAME}
echo "Stork database initialized"

# prepare stork certs
stork-tool cert-import --db-user ${STORK_DB_USER} --db-password ${STORK_DB_PASSWORD} --db-host $DB_HOST --db-name ${STORK_DB_NAME} --object cacert  --file /etc/stork/certs/ca.crt
openssl pkcs8 -topk8 -nocrypt -in /etc/stork/certs/ca.key | stork-tool cert-import --db-user ${STORK_DB_USER} --db-password ${STORK_DB_PASSWORD} --db-host $DB_HOST --db-name ${STORK_DB_NAME} --object cakey

stork-tool cert-import --db-user ${STORK_DB_USER} --db-password ${STORK_DB_PASSWORD} --db-host $DB_HOST --db-name ${STORK_DB_NAME} --object srvcert  --file /etc/stork/certs/server.crt
openssl pkcs8 -topk8 -nocrypt -in /etc/stork/certs/server.key | stork-tool cert-import --db-user ${STORK_DB_USER} --db-password ${STORK_DB_PASSWORD} --db-host $DB_HOST --db-name ${STORK_DB_NAME} --object srvkey

exit 0
