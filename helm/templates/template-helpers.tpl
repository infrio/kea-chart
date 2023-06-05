{{/*
Expand the name of the chart.
*/}}
{{- define "kea4.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kea4.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kea4.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kea4.labels" -}}
helm.sh/chart: {{ include "kea4.chart" . }}
{{ include "kea4.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kea4.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kea4.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: dhcp-core
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kea4.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kea4.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Add users to pgpool
*/}}
{{- define "pgpool-add-users" }}
#!/bin/bash

set -o errexit

/opt/bitnami/pgpool/bin/pg_enc --config-file=/opt/bitnami/pgpool/conf/pgpool.conf -k /opt/bitnami/pgpool/conf/.pgpoolkey -u {{ .Values.configDB.user }} {{ .Values.configDB.password }} -m
/opt/bitnami/pgpool/bin/pg_enc --config-file=/opt/bitnami/pgpool/conf/pgpool.conf -k /opt/bitnami/pgpool/conf/.pgpoolkey -u {{ .Values.storkDB.user }} {{ .Values.storkDB.password }} -m

{{- end }}

{{/*
Generate postgresql pool FQDN
*/}}
{{- define "pgpool-fqdn" }}
{{- $pgPoolName := include "postgresql-ha.pgpool" (index .Subcharts "postgresql-ha") }}
{{ printf "%s.%s.svc.cluster.local" $pgPoolName .Release.Namespace }}
{{- end }}
