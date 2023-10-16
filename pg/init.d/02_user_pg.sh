#!/usr/bin/env bash

cli_user() {
    export PGPASSWORD=${DB_ARC_PW} 
    psql --username "${db}" --dbname "${db}" ${*}
}

cli_root() {
    psql --username "$POSTGRES_USER" ${*}
}

# convention: db name is thee same as user name
create_user_db() {

    set -x
    cat <<EOF | cli_root
        CREATE USER ${db} PASSWORD '${DB_ARC_PW}';
        create database ${db};
        ALTER DATABASE ${db} SET synchronous_commit TO off;
        alter user ${db} replication;
        alter database ${db} owner to ${db};
        grant all privileges on database ${db} to ${db};
EOF

    if [[ "${ROLE^^}" = "SRC" ]]; then

        cat <<EOF | cli_root
            ALTER ROLE ${db} WITH REPLICATION;
            -- heartbeat table
            GRANT ALL ON DATABASE ${REPLICANT_DB} to ${db};
EOF

        cat <<EOF | cli_user
            SELECT 'init' FROM pg_create_logical_replication_slot('${db}_w2j', 'wal2json');
            SELECT * from pg_replication_slots;
            CREATE TABLE IF NOT EXISTS "REPLICATE_IO_CDC_HEARTBEAT"(
                TIMESTAMP BIGINT NOT NULL,
                PRIMARY KEY(TIMESTAMP)
            );            
EOF

    fi
    set +x
}

# below is the same of all of the databases

create_user() {
    local ROLE=${1}
    local DB_ARC_USER=${2} 
    local DB_ARC_PW=${3} 
    local DBS_COMMA=${4} 
    local SIZE_FACTOR=${5:-1}
    local SIZE_FACTOR_NAME

    if [ "${SIZE_FACTOR}" = "1" ]; then
        SIZE_FACTOR_NAME=""
    else
        SIZE_FACTOR_NAME=${SIZE_FACTOR}
    fi
    DB_ARC_USER=${DB_ARC_USER}${SIZE_FACTOR_NAME}

    # create names arcsrc arcsrc_ycsb srcsrc_tpcc 
    DB_NAMES=( ${DB_ARC_USER} \
         $(echo ${DBS_COMMA} | tr "," "\n" | xargs -I '{}' -n1 echo "${DB_ARC_USER}_{}") )

    for db in ${DB_NAMES[@]}; do
        create_user_db
    done
}

create_src() {
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then ROLE=SRC; else ROLE=DST; fi
    if [[ "${ROLE^^}" = "SRC" ]]; then
        create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${ARCDEMO_DB_NAMES}" 1
    fi
}

create_dst() {
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then ROLE=SRC; else ROLE=DST; fi
    create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${ARCDEMO_DB_NAMES}" 1 
}

# run if not being manually sourced
if [[ -z "${1}" ]]; then
    if [ ! -f ${LOGDIR}/02_user.txt ]; then
        create_src | tee -a ${LOGDIR}/02_user.txt
        create_dst | tee -a ${LOGDIR}/02_user.txt
    fi
fi