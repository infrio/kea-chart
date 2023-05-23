{{- define "stork-agent-credentials" }}
{
   "basic_auth": [
      {
         "ip": "127.0.0.1",
         "port": {{ .Values.service.agentPort }},
         "user": {{ index .Values "kea-agent" "user" | quote }},
         "password": {{ index .Values "kea-agent" "password" | quote }}
      }
   ]
}
{{- end }}


{{- define "stork-agent-env" -}}
STORK_AGENT_SKIP_TLS_CERT_VERIFICATION=true
STORK_AGENT_PORT={{ .Values.service.storkAgentPort }}
STORK_AGENT_SERVER_URL=https://stork.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.service.storkServerPort }}
STORK_AGENT_SERVER_HOST=stork.{{ .Release.Namespace }}.svc.cluster.local
STORK_AGENT_SERVER_PORT={{ .Values.service.storkServerPort }}
{{- end }}

{{- define "stork-server-env" -}}
STORK_REST_PORT={{ .Values.service.storkServerPort }}
STORK_REST_TLS_CERTIFICATE=/etc/stork/certs/stork-server.crt
STORK_REST_TLS_PRIVATE_KEY=/etc/stork/certs/stork-server.key

STORK_DATABASE_HOST={{ template "postgresql-ha.pgpool" (index .Subcharts "postgresql-ha") }}.{{ .Release.Namespace}}.svc.cluster.local
STORK_DATABASE_PORT={{- .Values.storkDB.port }}
STORK_DATABASE_NAME={{- .Values.storkDB.name }}
STORK_DATABASE_USER_NAME={{- .Values.storkDB.user }}
STORK_DATABASE_PASSWORD={{- .Values.storkDB.password }}
STORK_SERVER_ENABLE_METRICS=true
{{- end }}

{{- define "stork.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kea4.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: stork
{{- end }}
