#!/usr/bin/env bash

export USER_PREFIX=c##

setup_cdc() {

    sqlplus sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<EOF
        ALTER DATABASE FORCE LOGGING;
        ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
EOF
}

create_user_db() {

    set -x 
    sqlplus sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<EOF
    CREATE USER ${USER_PREFIX}${db} IDENTIFIED BY ${DB_ARC_PW};

    ALTER USER ${USER_PREFIX}${db} default tablespace USERS;

    ALTER USER ${USER_PREFIX}${db} quota unlimited on USERS;

    GRANT CREATE SESSION TO ${USER_PREFIX}${db};

    grant connect,resource to ${USER_PREFIX}${db};
    grant execute_catalog_role to ${USER_PREFIX}${db};
    grant select_catalog_role to ${USER_PREFIX}${db};

    grant dba to ${USER_PREFIX}${db};
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
    setup_cdc
    create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} "${ARCDEMO_DB_NAMES}" 1 | tee -a ${LOGDIR}/02_user.txt
}

create_dst() {
    create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} "${ARCDEMO_DB_NAMES}" 1 | tee -a ${LOGDIR}/02_user.txt
}

if [ ! -f ${LOGDIR}/02_user.txt ]; then
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then
        create_src 
        create_dst 
    elif [[ $(uname -a | awk '{print $2}') =~ dst$ ]]; then
        create_dst 
    else 
        create_src 
        create_dst 
    fi
fi