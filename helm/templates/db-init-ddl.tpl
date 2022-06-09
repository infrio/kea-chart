{{- define "kea-db-prep" }}
create database if not exists {{ .Values.configDB.name }};
create user if not exists '{{ .Values.configDB.user }}'@'%' identified by '{{ .Values.configDB.password }}';
grant all privileges on {{ .Values.configDB.name }}.* to '{{ .Values.configDB.user }}'@'%';

create database if not exists {{ .Values.leaseDB.name }};
create user if not exists '{{ .Values.leaseDB.user }}'@'%' identified by '{{ .Values.leaseDB.password }}';
grant all privileges on {{ .Values.leaseDB.name }}.* to '{{ .Values.leaseDB.user }}'@'%';

create database if not exists {{ .Values.hostDB.name }};
create user if not exists '{{ .Values.hostDB.user }}'@'%' identified by '{{ .Values.hostDB.password }}';
grant all privileges on {{ .Values.hostDB.name }}.* to '{{ .Values.hostDB.user }}'@'%';
{{- end }}