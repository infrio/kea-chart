{{/*
Generate certificates for stork components
*/}}

{{- define "stork-gen-certs" -}}

{{- $caName := "stork-ca" -}}
{{- $ca := genCAWithKey $caName 365 (genPrivateKey "ecdsa") -}}
{{- $caCertB64 := .Files.Get "stork-ca.crt" -}}
{{- $caKeyB64 := .Files.Get "stork-ca.key" -}}
{{ if ne $caCertB64 "" }}
  {{- $ca = buildCustomCert $caCertB64 $caKeyB64 -}}
{{ end }}

{{- $storkServiceName := "stork" -}}
{{- $storkAltNames := list (printf "%s.%s.svc" $storkServiceName .Release.Namespace) (printf "%s.%s.svc.cluster.local" $storkServiceName .Release.Namespace) -}}
{{- $serverCert := genSignedCertWithKey $storkServiceName nil $storkAltNames 365 $ca (genPrivateKey "ecdsa") -}}

{{- $agentName := "stork-agent" -}}
{{- $agentCert := genSignedCertWithKey $agentName nil nil 365 $ca (genPrivateKey "ecdsa") -}}

ca.crt: {{ $ca.Cert | b64enc}}
ca.key: {{ $ca.Key | b64enc}}
server.crt: {{ $serverCert.Cert | b64enc }}
server.key: {{ $serverCert.Key | b64enc }}
agent.crt: {{ $agentCert.Cert | b64enc }}
agent.key: {{ $agentCert.Key | b64enc }}

{{- end -}}
