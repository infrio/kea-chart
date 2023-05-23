{{/*
Create databases, users, and init tables
*/}}
{{- define "kea-admin-dbinit" }}
#!/bin/bash

set -o errexit

if [[ ! -e /etc/kea-db-config/password ]]; then
    echo "db config not found"
    exit 1
fi
PASSWORD=$(cat /etc/kea-db-config/password)
DB_HOST={{ template "postgresql-ha.pgpool" (index .Subcharts "postgresql-ha") }}.{{ .Release.Namespace}}.svc.cluster.local
DB_PORT="5432"

wait_for_psql(){
  until PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres --list > /dev/null; do
    echo "$DB_HOST:$DB_PORT is not ready"
    sleep 5
  done
}

wait_for_psql
echo "Database server is ready"

echo "select 'create database {{ .Values.configDB.name }}' where not exists (select from pg_database where datname = '{{ .Values.configDB.name }}')\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "select 'create user {{ .Values.configDB.user }} with superuser password null' where not exists (select from pg_user where usename = '{{ .Values.configDB.user }}')\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "alter user {{ .Values.configDB.user }} with encrypted password '{{ .Values.configDB.password }}'\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "grant all privileges on database {{ .Values.configDB.name }} to {{ .Values.configDB.user }}" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres

echo "select 'create database {{ .Values.leaseDB.name }}' where not exists (select from pg_database where datname = '{{ .Values.leaseDB.name }}')\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "select 'create user {{ .Values.leaseDB.user }} with superuser password null' where not exists (select from pg_user where usename = '{{ .Values.leaseDB.user }}')\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "alter user {{ .Values.leaseDB.user }} with encrypted password '{{ .Values.leaseDB.password }}'\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "grant all privileges on database {{ .Values.leaseDB.name }} to {{ .Values.leaseDB.user }}" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres

echo "select 'create database {{ .Values.hostDB.name }}' where not exists (select from pg_database where datname = '{{ .Values.hostDB.name }}')\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "select 'create user {{ .Values.hostDB.user }} with superuser password null' where not exists (select from pg_user where usename = '{{ .Values.hostDB.user }}')\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "alter user {{ .Values.hostDB.user }} with encrypted password '{{ .Values.hostDB.password }}'\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "grant all privileges on database {{ .Values.hostDB.name }} to {{ .Values.hostDB.user }}" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres

echo "select 'create database {{ .Values.storkDB.name }}' where not exists (select from pg_database where datname = '{{ .Values.storkDB.name }}')\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "select 'create user {{ .Values.storkDB.user }} with superuser password null' where not exists (select from pg_user where usename = '{{ .Values.storkDB.user }}')\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "alter user {{ .Values.storkDB.user }} with encrypted password '{{ .Values.storkDB.password }}'\gexec" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres
echo "grant all privileges on database {{ .Values.storkDB.name }} to {{ .Values.storkDB.user }}" | PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U postgres

echo "Databases created"

kea-admin db-init pgsql -u postgres -h $DB_HOST -p $PASSWORD -n {{ .Values.configDB.name }}
echo "Kea tables created"

stork-tool db-init --db-user {{ .Values.storkDB.user }} --db-password {{ .Values.storkDB.password }} --db-host $DB_HOST --db-name {{ .Values.storkDB.name }}
stork-tool db-up --db-user {{ .Values.storkDB.user }} --db-password {{ .Values.storkDB.password }} --db-host $DB_HOST --db-name {{ .Values.storkDB.name }}
echo "Stork tables created"

stork-tool cert-import --db-user {{ .Values.storkDB.user }} --db-password {{ .Values.storkDB.password }} --db-host $DB_HOST --db-name {{ .Values.storkDB.name }} --object cacert  --file /etc/stork/certs/ca.crt
openssl pkcs8 -topk8 -nocrypt -in /etc/stork/certs/ca.key | stork-tool cert-import --db-user {{ .Values.storkDB.user }} --db-password {{ .Values.storkDB.password }} --db-host $DB_HOST --db-name {{ .Values.storkDB.name }} --object cakey

stork-tool cert-import --db-user {{ .Values.storkDB.user }} --db-password {{ .Values.storkDB.password }} --db-host $DB_HOST --db-name {{ .Values.storkDB.name }} --object srvcert  --file /etc/stork/certs/server.crt
openssl pkcs8 -topk8 -nocrypt -in /etc/stork/certs/server.key | stork-tool cert-import --db-user {{ .Values.storkDB.user }} --db-password {{ .Values.storkDB.password }} --db-host $DB_HOST --db-name {{ .Values.storkDB.name }} --object srvkey

exit 0

{{- end }}

{{/*
Add users to pgpool
*/}}
{{- define "pgpool-add-users" }}
#!/bin/bash

set -o errexit

/opt/bitnami/pgpool/bin/pg_enc --config-file=/opt/bitnami/pgpool/conf/pgpool.conf -k /opt/bitnami/pgpool/conf/.pgpoolkey -u {{ .Values.configDB.user }} {{ .Values.configDB.password }} -m
/opt/bitnami/pgpool/bin/pg_enc --config-file=/opt/bitnami/pgpool/conf/pgpool.conf -k /opt/bitnami/pgpool/conf/.pgpoolkey -u {{ .Values.leaseDB.user }} {{ .Values.leaseDB.password }} -m
/opt/bitnami/pgpool/bin/pg_enc --config-file=/opt/bitnami/pgpool/conf/pgpool.conf -k /opt/bitnami/pgpool/conf/.pgpoolkey -u {{ .Values.hostDB.user }} {{ .Values.hostDB.password }} -m
/opt/bitnami/pgpool/bin/pg_enc --config-file=/opt/bitnami/pgpool/conf/pgpool.conf -k /opt/bitnami/pgpool/conf/.pgpoolkey -u {{ .Values.storkDB.user }} {{ .Values.storkDB.password }} -m

{{- end }}
