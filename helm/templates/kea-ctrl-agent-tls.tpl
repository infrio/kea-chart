{{/*
Generate certificates for kea control agent 
*/}}
{{- define "kea-ctrl-agent.gen-certs" -}}
{{- $serviceName := printf "%s-agent" (include "kea4.fullname" .) }}
{{- $caName := printf "%s-ca" ( .Release.Name ) }}
{{- $altNames := list (printf "%s.%s.svc" $serviceName .Release.Namespace) (printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace) -}}
{{- $ca := genCA  $caName  365 -}}
{{- $cert := genSignedCert $serviceName nil $altNames 365 $ca -}}
ca.crt: {{ $ca.Cert | b64enc}}
agent.crt: {{ $cert.Cert | b64enc }}
agent.key: {{ $cert.Key | b64enc }}
{{- end -}}