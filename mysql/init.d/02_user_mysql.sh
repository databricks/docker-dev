#!/usr/bin/env bash

# convention: db name is thee same as user name
create_user_db() {

    set -x
    mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
        CREATE USER '${db}'@'%' IDENTIFIED WITH mysql_native_password BY '${DB_ARC_PW}';
        CREATE USER '${db}'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '${DB_ARC_PW}';
        GRANT ALL ON ${db}.* to '${db}'@'%';
        GRANT ALL ON ${db}.* to '${db}'@'127.0.0.1';
        CREATE DATABASE ${db};
        CREATE TABLE IF NOT EXISTS ${db}.REPLICATE_IO_CDC_HEARTBEAT(
            TIMESTAMP BIGINT NOT NULL,
            PRIMARY KEY(TIMESTAMP)
        );
EOF

    if [[ "${ROLE^^}" = "SRC" ]]; then

        mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
        -- optional heartbeat table
        GRANT ALL ON ${REPLICANT_DB}.* to '${db}'@'%';
        GRANT ALL ON ${REPLICANT_DB}.* to '${db}'@'127.0.0.1';
        -- replication
        -- these grants cannot be limit to database.  has to be *.*
        GRANT REPLICATION CLIENT ON *.* TO '${db}'@'%';
        GRANT REPLICATION SLAVE ON *.* TO '${db}'@'%';
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
    if [[ "${ROLE^^}" = "DST" ]]; then
        create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${ARCDEMO_DB_NAMES}" 1 
    fi
}

# run if not being manually sourced
if [[ -z "${1}" ]]; then
    if [ ! -f ${LOGDIR}/02_user.txt ]; then
        create_src | tee -a ${LOGDIR}/02_user.txt
        create_dst | tee -a ${LOGDIR}/02_user.txt
    fi
fi