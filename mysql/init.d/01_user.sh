#!/usr/bin/env bash

# src
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

        mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
            CREATE USER '${db}'@'%' IDENTIFIED WITH mysql_native_password BY '${DB_ARC_PW}';
            CREATE USER '${db}'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '${DB_ARC_PW}';
            GRANT ALL ON ${db}.* to '${db}'@'%';
            GRANT ALL ON ${db}.* to '${db}'@'127.0.0.1';
            CREATE DATABASE ${db};
EOF

        if [ "${ROLE^^}" = "SRC" ]; then

            mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<EOF
            -- CDC
            -- these grants cannot be limit to database.  has to be *.*
            GRANT REPLICATION CLIENT ON *.* TO '${db}'@'%';
            GRANT REPLICATION SLAVE ON *.* TO '${db}'@'%';
EOF

        fi
    done
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