#!/usr/bin/env bash

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

    set -x

    for db in $(echo ${DBS_COMMA} | tr "," "\n"); do

        db="${DB_ARC_USER}_${db}"

        psql --username "$POSTGRES_USER" <<EOF
        CREATE USER ${db} PASSWORD '${DB_ARC_PW}';
        ALTER USER ${db} CREATEDB;
        ALTER ROLE ${db} WITH REPLICATION;
        CREATE DATABASE ${db} WITH OWNER ${db} ENCODING 'UTF8';
EOF


        if [ "${ROLE^^}" = "SRC" ]; then
            PGPASSWORD=${DB_ARC_PW} psql --username "${db}" <<EOF
            SELECT 'init' FROM pg_create_logical_replication_slot('${db}_w2j', 'wal2json');
EOF
        fi
    done

    PGPASSWORD=${DB_ARC_PW} psql --username "${db}" <<EOF
    SELECT * from pg_replication_slots;
EOF
    set -x
}

create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SF1_DBS_COMMA}" 1 
create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SF1_DBS_COMMA}" 1 

if [ -z "${ARCDEMO_DEBUG}" ]; then

    create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SFN_DBS_COMMA}" 10 
    create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SFN_DBS_COMMA}" 10 

    create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SFN_DBS_COMMA}" 100 
    create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SFN_DBS_COMMA}" 100 

fi