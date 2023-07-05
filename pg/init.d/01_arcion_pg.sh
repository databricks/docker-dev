#!/usr/bin/env bash

cli_user() {
    export PGPASSWORD=${REPLICANT_PW} 
    psql --username "${REPLICANT_USER}" --dbname "${REPLICANT_DB}"${*}
}

cli_root() {
    psql --username "$POSTGRES_USER" ${*}
}

create_heartbeat() {

    cat <<EOF | cli_root
        CREATE USER ${REPLICANT_USER} PASSWORD '${REPLICANT_PW}';
        ALTER USER ${REPLICANT_USER} CREATEDB;
        CREATE DATABASE ${REPLICANT_DB} WITH OWNER ${REPLICANT_USER} ENCODING 'UTF8';
EOF

    cat <<EOF | cli_user
        CREATE TABLE IF NOT EXISTS "REPLICATE_IO_CDC_HEARTBEAT"(
            TIMESTAMP BIGINT NOT NULL,
            PRIMARY KEY(TIMESTAMP)
        );
EOF

}

if [[ -z "${1}" ]]; then
    if [ ! -f ${LOGDIR}/01_arcion.txt ]; then
        if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then ROLE=SRC; else ROLE=DST; fi

        if [[ "${ROLE^^}" = "SRC" ]]; then
            create_heartbeat | tee -a ${LOGDIR}/01_arcion.txt 
        fi
    fi
fi