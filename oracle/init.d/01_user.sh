#!/usr/bin/env bash

# src
create_user() {
    local ROLE=${1}
    local DB_ARC_USER=${2} 
    local DB_ARC_PW=${3} 
    local DB_DB=${4} 
    local SIZE_FACTOR=${5}
    local DB_USER_PREFIX="c##"

    sqlplus sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<EOF
    CREATE USER ${DB_USER_PREFIX}${DB_ARC_USER}${SIZE_FACTOR} IDENTIFIED BY ${DB_ARC_PW};

    ALTER USER ${DB_USER_PREFIX}${DB_ARC_USER}${SIZE_FACTOR} default tablespace USERS;

    ALTER USER ${DB_USER_PREFIX}${DB_ARC_USER}${SIZE_FACTOR} quota unlimited on USERS;

    GRANT CREATE SESSION TO ${DB_USER_PREFIX}${DB_ARC_USER}${SIZE_FACTOR};

    grant connect,resource to ${DB_USER_PREFIX}${DB_ARC_USER}${SIZE_FACTOR};
    grant execute_catalog_role to ${DB_USER_PREFIX}${DB_ARC_USER}${SIZE_FACTOR};
    grant select_catalog_role to ${DB_USER_PREFIX}${DB_ARC_USER}${SIZE_FACTOR};
EOF
}

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB}  
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB}  

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 10 
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 10 

create_user SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 100 
create_user DST ${DSTDB_ARC_USER} ${DSTDB_ARC_PW} ${DSTDB_DB} 100