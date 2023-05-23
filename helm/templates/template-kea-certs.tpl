{{/*
Generate certificates for kea components
*/}}

{{- define "kea-gen-certs" -}}

{{- $caName := printf "%s-ca" ( .Release.Name ) }}
{{- $ca := genCA $caName 3650 -}}
{{- $caCertB64 := .Files.Get "ca.crt" -}}
{{- $caKeyB64 := .Files.Get "ca.key" -}}
{{ if ne $caCertB64 "" }}
  {{- $ca = buildCustomCert $caCertB64 $caKeyB64 -}}
{{ end }}

{{- $agentServiceName := printf "%s-agent" (include "kea4.fullname" .) -}}
{{- $agentAltNames := list (printf "%s.%s.svc" $agentServiceName .Release.Namespace) (printf "%s.%s.svc.cluster.local" $agentServiceName .Release.Namespace) -}}
{{- $agentCert := genSignedCert $agentServiceName nil $agentAltNames 3650 $ca -}}

{{- $storkServerAltNames := list (printf "stork.%s.svc" .Release.Namespace) (printf "stork.%s.svc.cluster.local" .Release.Namespace) -}}
{{- $storkServerCert := genSignedCert "stork" nil $storkServerAltNames 3650 $ca -}}

{{- $storkAgentCert := genSignedCertWithKey "stork-agent" nil nil 365 $ca (genPrivateKey "ecdsa") -}}

ca.crt: {{ $ca.Cert | b64enc}}
ca.key: {{ $ca.Key | b64enc}}
ctrl-agent.crt: {{ $agentCert.Cert | b64enc }}
ctrl-agent.key: {{ $agentCert.Key | b64enc }}
stork-server.crt: {{ $storkServerCert.Cert | b64enc }}
stork-server.key: {{ $storkServerCert.Key | b64enc }}
stork-agent.crt: {{ $storkAgentCert.Cert | b64enc }}
stork-agent.key: {{ $storkAgentCert.Key | b64enc }}

{{- end -}}
