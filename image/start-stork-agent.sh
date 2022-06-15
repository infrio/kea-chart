#!/bin/bash

set -o errexit
set -a

PYPROG=$(cat <<EOF
import json
with open("/etc/kea/ctrl-agent.conf") as file:
    content = file.read()
    conf = json.loads(content)
    print("CTRL_AGENT_HOST=%s" % conf['Control-agent']['http-host'])
    print("CTRL_AGENT_PORT=%s" % conf['Control-agent']['http-port'])
EOF
)

eval `python3 -c "$PYPROG"`

. /etc/stork/agent.env
. /etc/stork/server.env

wait_for_ctrl_agent(){
  until nc -vz $CTRL_AGENT_HOST $CTRL_AGENT_PORT > /dev/null; do
    echo "$CTRL_AGENT_HOST:$CTRL_AGENT_PORT is unavailable - wait"
    sleep 3
  done
}

wait_for_psql(){
  until nc -vz $STORK_DATABASE_HOST $STORK_DATABASE_PORT > /dev/null; do
    echo "$STORK_DATABASE_HOST:$STORK_DATABASE_PORT is unavailable - sleeping"
    sleep 3
  done
  echo "$STORK_DATABASE_HOST:$STORK_DATABASE_PORT is up"

  until PGPASSWORD=$STORK_DATABASE_PASSWORD psql -h $STORK_DATABASE_HOST -U $STORK_DATABASE_USER_NAME -d $STORK_DATABASE_NAME -c "select * from gopg_migrations" > /dev/null; do
    echo "Stork database is not ready, keep waiting"
    sleep 3
  done
}

wait_for_stork_server(){
  until nc -vz $STORK_AGENT_SERVER_HOST $STORK_AGENT_SERVER_PORT > /dev/null; do
    echo "$STORK_AGENT_SERVER_HOST:$STORK_AGENT_SERVER_PORT is unavailable - wait"
    sleep 3
  done
}

wait_for_ctrl_agent
echo "kea-ctrl-agent is up"
wait_for_psql
echo "Stork database is ready"

/usr/bin/stork-tool cert-export --db-user $STORK_DATABASE_USER_NAME --db-password $STORK_DATABASE_PASSWORD --db-host $STORK_DATABASE_HOST --db-name $STORK_DATABASE_NAME --object srvtkn  --file /var/lib/stork-agent/tokens/server-token.txt
/usr/bin/stork-tool cert-export --db-user $STORK_DATABASE_USER_NAME --db-password $STORK_DATABASE_PASSWORD --db-host $STORK_DATABASE_HOST --db-name $STORK_DATABASE_NAME --object cacert  --file /var/lib/stork-agent/certs/ca.pem
# cp /etc/stork/certs/agent.crt /var/lib/stork-agent/certs/cert.pem

wait_for_stork_server
echo "Stork server is ready"

/usr/bin/stork-agent register --server-url $STORK_AGENT_SERVER_URL --agent-host $(hostname -i):8080 --server-token $(cat /var/lib/stork-agent/tokens/server-token.txt) &
/usr/bin/stork-agent --server-url $STORK_AGENT_SERVER_URL --host $(hostname -i) --skip-tls-cert-verification
