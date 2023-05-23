#!/bin/bash

set -o errexit

. /etc/stork/agent.env
. /etc/stork/server.env

MY_IP=$(ip -o -4 addr show dev eth0 | awk '{split($4,a,"/"); print a[1]}')

wait_for_stork_agent(){
  until nc -vz ${MY_IP} ${STORK_AGENT_PORT} > /dev/null; do
    echo "${MY_IP}:${STORK_AGENT_PORT} is unavailable - wait"
    sleep 3
  done
}

wait_for_stork_agent
echo "Stork Agent is up"

mkdir -p /var/lib/stork-agent/tokens
mkdir -p /var/lib/stork-agent/certs
/usr/bin/stork-tool cert-export --db-user $STORK_DATABASE_USER_NAME --db-password $STORK_DATABASE_PASSWORD --db-host $STORK_DATABASE_HOST --db-name $STORK_DATABASE_NAME --object srvtkn  --file /var/lib/stork-agent/tokens/server-token.txt
/usr/bin/stork-tool cert-export --db-user $STORK_DATABASE_USER_NAME --db-password $STORK_DATABASE_PASSWORD --db-host $STORK_DATABASE_HOST --db-name $STORK_DATABASE_NAME --object cacert  --file /var/lib/stork-agent/certs/ca.pem
cp /etc/stork/certs/stork-agent.crt /var/lib/stork-agent/certs/cert.pem
cp /etc/stork/certs/stork-agent.key /var/lib/stork-agent/certs/key.pem
cp /etc/stork/certs/ca.crt /usr/local/share/ca-certificates/stork.crt
update-ca-certificates

/usr/bin/stork-agent register --server-url ${STORK_AGENT_SERVER_URL} --agent-host ${MY_IP}:${STORK_AGENT_PORT} --server-token $(cat /var/lib/stork-agent/tokens/server-token.txt)

exit 0
