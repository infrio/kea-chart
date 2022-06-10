#!/bin/bash

set -o errexit

PYPROG=$(cat <<EOF
import json
with open("/etc/kea/ctrl-agent.conf") as file:
    content = file.read()
    conf = json.loads(content)
    print("KEA4_SOCKET=%s" % conf['Control-agent']['control-sockets']['dhcp4']['socket-name'])
EOF
)

eval `python3 -c "$PYPROG"`

wait_for_dhcp4(){
  until stat $KEA4_SOCKET > /dev/null; do
    echo "kea dhcp4 is not ready - sleep"
    sleep 5
  done
}

wait_for_dhcp4
echo "kea dhcp4 is up"

/usr/sbin/kea-ctrl-agent -c /etc/kea/ctrl-agent.conf
