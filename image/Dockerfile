FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get -y install gnupg curl && \
    curl -sL 'https://dl.cloudsmith.io/public/isc/kea-2-1/gpg.32D53EC4807EC10E.key' | gpg --dearmor > /usr/share/keyrings/kea-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kea-archive-keyring.gpg] https://dl.cloudsmith.io/public/isc/kea-2-1/deb/debian bullseye main" > /etc/apt/sources.list.d/kea.list && \
    apt-get update && \
    apt-get -y install isc-kea-admin isc-kea-ctrl-agent isc-kea-dhcp4-server mariadb-client netcat

ADD start-dhcp4.sh /usr/local/bin/start-dhcp4.sh
ADD start-ctrl-agent.sh /usr/local/bin/start-ctrl-agent.sh