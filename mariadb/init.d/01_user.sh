#!/usr/bin/env bash

# src
create_user() {
    local ROLE=${1}
    local DB_ARC_USER=${2} 
    local DB_ARC_PW=${3} 
    local DB_DB=${4} 
    local SIZE_FACTOR=${5}

    mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
    CREATE USER IF NOT EXISTS '${DB_ARC_USER}${SIZE_FACTOR}'@'%' IDENTIFIED BY '${DB_ARC_PW}';
    CREATE USER IF NOT EXISTS '${DB_ARC_USER}${SIZE_FACTOR}'@'127.0.0.1' IDENTIFIED BY '${DB_ARC_PW}';

    GRANT ALL ON ${DB_DB}${SIZE_FACTOR}.* to '${DB_ARC_USER}${SIZE_FACTOR}'@'%';
    GRANT ALL ON ${DB_DB}${SIZE_FACTOR}.* to '${DB_ARC_USER}${SIZE_FACTOR}'@'127.0.0.1';

    CREATE DATABASE IF NOT EXISTS ${DB_DB}${SIZE_FACTOR};
EOF

    if [ "${ROLE^^}" = "SRC" ]; then

    mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
    -- CDC
    -- these grants cannot be limit to database.  has to be *.*
    GRANT REPLICATION CLIENT ON *.* TO '${DB_ARC_USER}${SIZE_FACTOR}'@'%';
    GRANT REPLICATION SLAVE ON *.* TO '${DB_ARC_USER}${SIZE_FACTOR}'@'%';
EOF

    fi
}

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB}  
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB}  

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 10 
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 10 

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 100 
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 100