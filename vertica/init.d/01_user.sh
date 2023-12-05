#!/usr/bin/env bash

create_user() {
    local ROLE=${1}
    local DB_ARC_USER=${2} 
    local DB_ARC_PW=${3} 
    local DB_DB=${4} 
    local SIZE_FACTOR=${5}

    psql --username "$POSTGRES_USER" <<EOF
    CREATE USER ${DB_ARC_USER}${SIZE_FACTOR} PASSWORD '${DB_ARC_PW}';
    ALTER USER ${DB_ARC_USER}${SIZE_FACTOR} CREATEDB;
    ALTER ROLE ${DB_ARC_USER}${SIZE_FACTOR} WITH REPLICATION;
    CREATE DATABASE ${DB_DB}${SIZE_FACTOR} WITH OWNER ${DB_ARC_USER}${SIZE_FACTOR} ENCODING 'UTF8';
EOF

    if [ "${ROLE^^}" = "SRC" ]; then

    psql --username "$POSTGRES_USER" <<EOF
    SELECT 'init' FROM pg_create_logical_replication_slot('${DB_DB}${SIZE_FACTOR}_w2j', 'wal2json');
    SELECT * from pg_replication_slots;
EOF

    fi
}

create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB}  
create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB}  

create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 10 
create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 10 

create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 100 
create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 100 