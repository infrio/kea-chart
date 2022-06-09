{{- define "kea4-config" }}
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [
        "eth0"
      ],
      "dhcp-socket-type": "raw"
    },
    "control-socket": {
      "socket-type": "unix",
      "socket-name": {{ .Values.kea.unixSocket | quote }}
    },
    "config-control": {
      "config-databases": [
        {
          "type": "mysql",
          "name": {{ .Values.configDB.name | quote }},
          "user": {{ .Values.configDB.user | quote }},
          "host": "{{ template "common.names.fullname" (index .Subcharts "mariadb-galera") }}.{{ .Release.Namespace}}.svc.cluster.local",
          "port": {{ .Values.configDB.port }},
          "password": {{ .Values.configDB.password | quote }}
        }
      ],
      "config-fetch-wait-time": 20
    },
    "lease-database": {
      "type": "mysql",
      "name": {{ .Values.leaseDB.name | quote }},
      "user": {{ .Values.leaseDB.user | quote }},
      "host": "{{ template "common.names.fullname" (index .Subcharts "mariadb-galera") }}.{{ .Release.Namespace}}.svc.cluster.local",
      "password": {{ .Values.leaseDB.password | quote }},
      "lfc-interval": 3600
    },
    "hosts-database": {
      "type": "mysql",
      "name": {{ .Values.hostDB.name | quote }},
      "user": {{ .Values.leaseDB.user | quote }},
      "host": "{{ template "common.names.fullname" (index .Subcharts "mariadb-galera") }}.{{ .Release.Namespace}}.svc.cluster.local",
      "password": {{ .Values.leaseDB.password | quote }}
    },
    "expired-leases-processing": {
      "reclaim-timer-wait-time": 10,
      "flush-reclaimed-timer-wait-time": 25,
      "hold-reclaimed-time": 3600,
      "max-reclaim-leases": 100,
      "max-reclaim-time": 250,
      "unwarned-reclaim-cycles": 5
    },
    "renew-timer": 900,
    "rebind-timer": 1800,
    "valid-lifetime": 3600,
    "hooks-libraries": [
      {
        "library": "/usr/lib/x86_64-linux-gnu/kea/hooks/libdhcp_mysql_cb.so"
      },
      {
        "library": "/usr/lib/x86_64-linux-gnu/kea/hooks/libdhcp_stat_cmds.so"
      }
    ],
    "loggers": [
      {
        "name": "kea-dhcp4",
        "output_options": [
          {
            "output": "stdout",
            "pattern": "%-5p %m\n"
          }
        ],
        "severity": "INFO",
        "debuglevel": 0
      }
    ]
  }
}
{{- end }}