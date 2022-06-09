{{- define "kea-admin-dbinit" }}
#!/bin/bash

set -o errexit

if [[ ! -e /etc/kea-db-config/mariadb-root-password ]]; then
    echo "db config not found"
    exit 1
fi
PASSWORD=$(cat /etc/kea-db-config/mariadb-root-password)
DB_HOST={{ template "common.names.fullname" (index .Subcharts "mariadb-galera") }}.{{ .Release.Namespace}}.svc.cluster.local

wait_for_mysql(){
  until nc -vz $DB_HOST 3306 > /dev/null; do
    echo "$DB_HOST:3306 is unavailable - sleeping"
    sleep 5
  done
  echo "$DB_HOST:3306 is up"

  until mysql -h $DB_HOST -u root -p$PASSWORD --execute="SHOW STATUS where Variable_name='wsrep_ready';" | grep wsrep_ready | grep ON > /dev/null; do
    echo "Galera cluster is not ready - sleeping"
    sleep 5
  done
  echo "DB is ready"
}


wait_for_mysql $DB_HOST
echo "DB is ready"

mysql -u root -p$PASSWORD -h $DB_HOST < /etc/kea-db-init/prep.sql
echo "databases created"

kea-admin db-init mysql -u root -h $DB_HOST -p $PASSWORD -n {{ .Values.configDB.name }}
echo "kea tables created"

exit 0
{{- end }}