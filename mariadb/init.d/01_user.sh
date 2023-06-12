#!/usr/bin/env bash

# src
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

    mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
    CREATE USER IF NOT EXISTS '${DB_ARC_USER}${SIZE_FACTOR_NAME}'@'%' IDENTIFIED BY '${DB_ARC_PW}';
    CREATE USER IF NOT EXISTS '${DB_ARC_USER}${SIZE_FACTOR_NAME}'@'127.0.0.1' IDENTIFIED BY '${DB_ARC_PW}';
EOF

    for db in $(echo ${DB_DB} | tr "," "\n"); do
        mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
        GRANT ALL ON ${db}${SIZE_FACTOR_NAME}.* to '${DB_ARC_USER}${SIZE_FACTOR_NAME}'@'%';
        GRANT ALL ON ${db}${SIZE_FACTOR_NAME}.* to '${DB_ARC_USER}${SIZE_FACTOR_NAME}'@'127.0.0.1';

        CREATE DATABASE ${db}${SIZE_FACTOR_NAME};
EOF
    done

    if [ "${ROLE^^}" = "SRC" ]; then

    mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
    -- CDC
    -- these grants cannot be limit to database.  has to be *.*
    GRANT REPLICATION CLIENT ON *.* TO '${DB_ARC_USER}${SIZE_FACTOR_NAME}'@'%';
    GRANT REPLICATION SLAVE ON *.* TO '${DB_ARC_USER}${SIZE_FACTOR_NAME}'@'%';
EOF

    fi
}

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 1 
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 1 

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 10 
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 10 

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 100 
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 100