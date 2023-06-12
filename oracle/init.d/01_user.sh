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
    DB_ARC_USER="c##${DB_ARC_USER}${SIZE_FACTOR_NAME}"

    set -x

    for db in $(echo ${DBS_COMMA} | tr "," "\n"); do

        db="${DB_ARC_USER}_${db}"

        sqlplus sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<EOF
        CREATE USER ${db} IDENTIFIED BY ${DB_ARC_PW};

        ALTER USER ${db} default tablespace USERS;

        ALTER USER ${db} quota unlimited on USERS;

        GRANT CREATE SESSION TO ${db};

        grant connect,resource to ${db};
        grant execute_catalog_role to ${db};
        grant select_catalog_role to ${db};
EOF
    done
}

create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SF1_DBS_COMMA}" 1 
create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SF1_DBS_COMMA}" 1 

if [ -z "${ARCDEMO_DEBUG}" ]; then

    create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SFN_DBS_COMMA}" 10 
    create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SFN_DBS_COMMA}" 10 

    create_user "SRC" ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${SFN_DBS_COMMA}" 100 
    create_user "DST" ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${SFN_DBS_COMMA}" 100 

fi