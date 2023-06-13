#!/usr/bin/env bash

# dbname = username {username}{sizefactor}_{schema}
# arcsrc_tpcc
# arcsrc10_ycsb

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

        singlestore -f -u root --password=${ROOT_PASSWORD} <<EOF
            CREATE USER '${db}'@'%' IDENTIFIED BY '${DB_ARC_PW}';
            CREATE USER '${db}'@'127.0.0.1' IDENTIFIED BY '${DB_ARC_PW}';
            CREATE DATABASE ${db};
            GRANT ALL ON ${db}.* to '${db}'@'%';
            GRANT ALL ON ${db}.* to '${db}'@'127.0.0.1';
            -- heartbeat table
            GRANT ALL ON ${REPLICANT_DB}.* to '${db}'@'%';
            GRANT ALL ON ${REPLICANT_DB}.* to '${db}'@'127.0.0.1';
EOF
    done
    set +x
}

create_src() {
    create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SF1_DBS_COMMA}" 1
    if [ -z "${ARCDEMO_DEBUG}" ]; then 
    create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SFN_DBS_COMMA}" 10 
    create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SFN_DBS_COMMA}" 100 
    fi
}

create_dst() {
    create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SF1_DBS_COMMA}" 1 
    if [ -z "${ARCDEMO_DEBUG}" ]; then 
    create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SFN_DBS_COMMA}" 10 
    create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SFN_DBS_COMMA}" 100
    fi
}

if [[ $(hostname) =~ src$ ]]; then
    create_src
elif [[ $(hostname) =~ dst$ ]]; then
    create_dst
else 
    create_src
    create_dst
fi