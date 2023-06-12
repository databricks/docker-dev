#!/usr/bin/env bash

create_user() {
    local ROLE=${1}
    local DB_ARC_USER=${2} 
    local DB_ARC_PW=${3} 
    local DB_DB=${4} 
    local SIZE_FACTOR=${5:-1}
    local DB_NAMES_COMMA=${6:-"tpcc,tpch"}
    local SIZE_FACTOR_NAME

    if [ "${SIZE_FACTOR}" = "1" ]; then
        SIZE_FACTOR_NAME=""
    else
        SIZE_FACTOR_NAME=${SIZE_FACTOR}
    fi

    for db in $(echo ${DB_NAMES_COMMA} | tr "," "\n"); do
        DB_DB="${DB_DB},${DB_ARC_USER}_${db}"
    done

    psql --username "$POSTGRES_USER" <<EOF
    CREATE USER ${DB_ARC_USER}${SIZE_FACTOR_NAME} PASSWORD '${DB_ARC_PW}';
    ALTER USER ${DB_ARC_USER}${SIZE_FACTOR_NAME} CREATEDB;
    ALTER ROLE ${DB_ARC_USER}${SIZE_FACTOR_NAME} WITH REPLICATION;
EOF

    # create databases for the user
    for db in $(echo ${DB_DB} | tr "," "\n"); do
        psql --username "$POSTGRES_USER" <<EOF
        CREATE DATABASE ${db}${SIZE_FACTOR_NAME} WITH OWNER ${DB_ARC_USER}${SIZE_FACTOR_NAME} ENCODING 'UTF8';
EOF
    done

    if [ "${ROLE^^}" = "SRC" ]; then
        for db in $(echo ${DB_DB} | tr "," "\n"); do
            PGPASSWORD=${DB_ARC_PW} psql --username "${DB_ARC_USER}${SIZE_FACTOR_NAME}" <<EOF
            SELECT 'init' FROM pg_create_logical_replication_slot('${db}${SIZE_FACTOR_NAME}_w2j', 'wal2json');
EOF
        done

        PGPASSWORD=${DB_ARC_PW} psql --username "${DB_ARC_USER}${SIZE_FACTOR_NAME}" <<EOF
        SELECT * from pg_replication_slots;
EOF

    fi
}

create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 1 
create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 1 

create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 10 
create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 10 

create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 100 
create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 100 