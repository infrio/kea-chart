{{/*
Generate control agent config file
*/}}
{{- define "kea-ctrl-agent-config" }}
{
    "Control-agent": {
      "http-host": "0.0.0.0",
      "http-port": 8443,
      "trust-anchor": "/etc/kea/certs/ca.crt",
      "cert-file": "/etc/kea/certs/ctrl-agent.crt",
      "key-file": "/etc/kea/certs/ctrl-agent.key",
      "cert-required": false,
      "authentication": {
        "type": "basic",
        "realm": "kea-control-agent",
        "clients": [
          {
            "user": {{ index .Values "kea-agent" "user" | quote }},
            "password": {{ index .Values "kea-agent" "password" | quote }}
          }
        ]
      },
      "control-sockets": {
        "dhcp4": {
          "comment": "dhcp4 agent",
          "socket-type": "unix",
          "socket-name": "{{- .Values.kea.unixSocket }}"
        }
      },
      "loggers": [
        {
          "name": "kea-ctrl-agent",
          "output_options": [
            {
              "output": "stdout",
              "pattern": "%-5p %m\n"
            }
          ],
          "severity": "INFO"
        }
      ]
    }
}
{{- end }}


{{- define "kea-ctrl-agent-auth-token" }}
{{- $login := index .Values "kea-agent" "user"  -}}
{{- $password := index .Values "kea-agent" "password"  -}}
{{- $plain := printf "%s:%s" $login $password -}}
{{ $plain | b64enc }}
{{- end -}}
