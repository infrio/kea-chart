#!/bin/bash

set -o errexit

PYPROG=$(cat <<EOF
import json
with open("/etc/kea/dhcp4.conf") as file:
    content = file.read()
    conf = json.loads(content)
    print("USER=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['user'])
    print("PASSWORD=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['password'])
    print("DB_HOST=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['host'])
    print("DB_PORT=%s" % conf['Dhcp4']['config-control']['config-databases'][0]['port'])
EOF
)

eval `python3 -c "$PYPROG"`
EXPECTED_SCHEMA_VERSION=$(kea-dhcp4 -V | grep -i "mysql backend" | tr -d ',' | cut -d' ' -f 3)

wait_for_mysql(){
  until nc -vz $DB_HOST $DB_PORT > /dev/null; do
    echo "$DB_HOST:$DB_PORT is unavailable - sleeping"
    sleep 5
  done
  echo "$DB_HOST:$DB_PORT is up"

  ACTUAL_SCHEMA_VERSION=$(mysql -h $DB_HOST -P $DB_PORT -u $USER -p$PASSWORD dhcp -NB --execute="select concat(version,concat('.' ,minor)) from schema_version")

  until [ "$ACTUAL_SCHEMA_VERSION" = "$EXPECTED_SCHEMA_VERSION" ]; do
    echo "Schema version $EXPECTED_SCHEMA_VERSION expected, got $ACTUAL_SCHEMA_VERSION, keep waiting"
    sleep 5
    ACTUAL_SCHEMA_VERSION=$(mysql -h $DB_HOST -P $DB_PORT -u $USER -p$PASSWORD dhcp -NB --execute="select concat(version,concat('.' ,minor)) from schema_version")
  done
}

wait_for_mysql
echo "Kea DB schema is ready"

/usr/sbin/kea-dhcp4 -c /etc/kea/dhcp4.conf
