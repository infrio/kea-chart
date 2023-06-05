FROM debian:bullseye-slim

RUN apt-get update &&\
    apt-get -y install gnupg curl && \
    curl -sL 'https://dl.cloudsmith.io/public/isc/kea-2-3/gpg.DA05D46B7BABA24A.key' | gpg --dearmor --output /usr/share/keyrings/kea-archive-keyring.gpg && \
    curl -sL 'https://dl.cloudsmith.io/public/isc/stork/gpg.77F64EC28053D1FB.key' |  gpg --dearmor --output /usr/share/keyrings/stork-archive-keyring.gpg && \
    curl -sL 'https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc' | gpg --dearmor --output /usr/share/keyrings/pgdg-archive-keyring.gpg

FROM debian:bullseye-slim as kea

COPY --from=0 /usr/share/keyrings/ /usr/share/keyrings/
COPY --from=0 /usr/share/keyrings/kea-archive-keyring.gpg /usr/share/keyrings/stork-archive-keyring.gpg /usr/share/keyrings/pgdg-archive-keyring.gpg /etc/apt/trusted.gpg.d/
RUN apt-get update && \
    apt-get -y install ca-certificates && \
    echo "deb [signed-by=/usr/share/keyrings/kea-archive-keyring.gpg] https://dl.cloudsmith.io/public/isc/kea-2-3/deb/debian bullseye main" > /etc/apt/sources.list.d/kea.list && \
    echo "deb [signed-by=/usr/share/keyrings/stork-archive-keyring.gpg] https://dl.cloudsmith.io/public/isc/stork/deb/debian bullseye main" >> /etc/apt/sources.list.d/kea.list && \
    echo "deb [signed-by=/usr/share/keyrings/pgdg-archive-keyring.gpg] http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get -y install curl python3 isc-kea-common isc-kea-admin isc-kea-ctrl-agent isc-kea-dhcp4 isc-kea-hooks isc-stork-agent isc-stork-server netcat postgresql-client-15 iproute2

ADD setup-kea-dbs.sh /usr/local/bin/setup-kea-dbs.sh
ADD start-dhcp4.sh /usr/local/bin/start-dhcp4.sh
ADD start-ctrl-agent.sh /usr/local/bin/start-ctrl-agent.sh
ADD start-stork-agent.sh /usr/local/bin/start-stork-agent.sh
ADD register-stork-agent.sh /usr/local/bin/register-stork-agent.sh
ADD start-stork-server.sh /usr/local/bin/start-stork-server.sh
