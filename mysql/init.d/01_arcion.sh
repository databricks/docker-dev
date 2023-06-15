#!/usr/bin/env bash

create_heartbeat() {

    mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
        CREATE USER '${REPLICANT_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${REPLICANT_PW}';
        CREATE USER '${REPLICANT_USER}'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '${REPLICANT_PW}';
        CREATE DATABASE ${REPLICANT_DB};
        GRANT ALL ON ${REPLICANT_DB}.* to '${REPLICANT_USER}'@'%';
        GRANT ALL ON ${REPLICANT_DB}.* to '${REPLICANT_USER}'@'127.0.0.1';
EOF

    mysql -u ${REPLICANT_USER} --password=${REPLICANT_PW} <<EOF
        USE ${REPLICANT_DB};
        CREATE TABLE IF NOT EXISTS REPLICATE_IO_CDC_HEARTBEAT(
            TIMESTAMP BIGINT NOT NULL,
            PRIMARY KEY(TIMESTAMP)
        );
EOF

}

if [[ -z "${1}" ]]; then
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then ROLE=SRC; else ROLE=DST; fi

    if [[ "${ROLE^^}" = "SRC" ]]; then
        create_heartbeat
    fi
fi