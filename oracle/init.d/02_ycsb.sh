#!/usr/bin/env bash

export USER_PREFIX=c##

cli_user() {
    sqlplus ${db}/${DB_ARC_PW}    
}

cli_root() {
    sqlplus sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba 
}

ycsb_create_db() {
cat <<EOF
CREATE TABLE THEUSERTABLE${SIZE_FACTOR_NAME} (
    YCSB_KEY NUMBER PRIMARY KEY,
    FIELD0 VARCHAR2(255), FIELD1 VARCHAR2(255),
    FIELD2 VARCHAR2(255), FIELD3 VARCHAR2(255),
    FIELD4 VARCHAR2(255), FIELD5 VARCHAR2(255),
    FIELD6 VARCHAR2(255), FIELD7 VARCHAR2(255),
    FIELD8 VARCHAR2(255), FIELD9 VARCHAR2(255)
) organization index; 
EOF
}

ycsb_load_db() {
    
    set -x
    ycsb_create_db | cli_user

    # setup name pipe for the table
    rm /tmp/ycsb.fifo.$$ 2>/dev/null
    mkfifo /tmp/ycsb.fifo.$$
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > /tmp/ycsb.fifo.$$ &
    
    # load data statement
    cat <<EOF >/tmp/ycsb.ctl.$$
    LOAD DATA
    INTO TABLE THEUSERTABLE${SIZE_FACTOR_NAME}
    FIELDS terminated by '|' trailing nullcols
    (
        YCSB_KEY
    )
EOF

    # don't generate logging for batch load
    echo "alter table THEUSERTABLE${SIZE_FACTOR_NAME} nologging;" | cli_user
        
    # load
    sqlldr ${db}/${DB_ARC_PW} \
        control=/tmp/ycsb.ctl.$$ \
        data=/tmp/ycsb.fifo.$$ \
        log=/tmp/ycsb.log.$$ \
        discard=/tmp/ycsb.dsc.$$ \
        direct=y \
        ERRORS=0

    # done.  generate logging
    echo "alter table THEUSERTABLE${SIZE_FACTOR_NAME} logging;" | cli_user

    # show report of the load
    cat /tmp/ycsb.log.$$
    rm /tmp/ycsb*.$$

    set +x
}

# below is the same of all of the databases

ycsb_load() {
    local ROLE=${1}
    local DB_ARC_USER=${2} 
    local DB_ARC_PW=${3} 
    local DB_DB=${4} 
    local SIZE_FACTOR=${5:-1}
    local SIZE_FACTOR_NAME

    if [ "${SIZE_FACTOR}" = "1" ]; then
        SIZE_FACTOR_NAME=""
    else
        SIZE_FACTOR_NAME=${SIZE_FACTOR}
    fi

    db="${USER_PREFIX}${DB_ARC_USER}"

    ycsb_load_db
}

create_src() {
    # 1M rows (2MB), 10M (25MB) and 100M (250MB) 1B (2.5G) rows
    time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1
    time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10 
    time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100
    time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 500
}

(return 0 2>/dev/null) && sourced=1 || sourced=0

if (( sourced != 1 )); then
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then
        create_src
    fi
fi