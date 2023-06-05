#!/bin/bash

set -o errexit

export CONFIG_FILE=$1

PYPROG=$(cat <<EOF
import json,os
config_file = os.environ.get("CONFIG_FILE")
with open(config_file) as file:
    content = file.read()
    conf = json.loads(content)
    print("USER=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['user'])
    print("PASSWORD=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['password'])
    print("DB_HOST=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['host'])
    print("DB_PORT=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['port'])
    print("DB_NAME=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['name'])
EOF
)

eval `python3 -c "$PYPROG"`
EXPECTED_SCHEMA_VERSION=$(kea-dhcp4 -V | grep -i "PostgreSQL backend" | tr -d ',' | cut -d' ' -f 3)

wait_for_psql(){
  until nc -vz $DB_HOST $DB_PORT > /dev/null; do
    echo "$DB_HOST:$DB_PORT is unavailable - sleeping"
    sleep 5
  done
  echo "$DB_HOST:$DB_PORT is up"

  ACTUAL_SCHEMA_VERSION=$(echo "select version||'.'||minor from schema_version" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -U $USER -d $DB_NAME -t | tr -d ' ')

  until [ "$ACTUAL_SCHEMA_VERSION" = "$EXPECTED_SCHEMA_VERSION" ]; do
    echo "Schema version $EXPECTED_SCHEMA_VERSION expected, got $ACTUAL_SCHEMA_VERSION, keep waiting"
    sleep 5
    ACTUAL_SCHEMA_VERSION=$(echo "select version||'.'||minor from schema_version" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -U $USER -d $DB_NAME -t | tr -d ' ')
  done
}

wait_for_psql
echo "Kea DB schema is ready"

/usr/sbin/kea-dhcp4 -c ${CONFIG_FILE}
