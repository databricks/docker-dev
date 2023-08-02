#!/usr/bin/env bash

create_user_db() {
    set -x
    singlestore -f -u root --password=${ROOT_PASSWORD} <<EOF
        CREATE USER '${db}' IDENTIFIED BY '${DB_ARC_PW}';
        CREATE DATABASE ${db};
        GRANT ALL ON ${db}.* to '${db}';
EOF
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
    create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${ARCDEMO_DB_NAMES}" 1
}

create_dst() {
    create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${ARCDEMO_DB_NAMES}" 1 
}

if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then
    create_src
elif [[ $(uname -a | awk '{print $2}') =~ dst$ ]]; then
    create_dst
else 
    create_src
    create_dst
fi