#!/usr/bin/env bash

export USER_PREFIX=c##

cli_user() {
    echo sqlplus ${db}/${DB_ARC_PW}@${ORACLE_SID} >&2
    sqlplus ${db}/${DB_ARC_PW}@${ORACLE_SID}    
}

cli_root() {
    sqlplus sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba 
}

ycsb_create_db() {
cat <<EOF
CREATE TABLE YCSBSPARSE${SIZE_FACTOR_NAME} (
    YCSB_KEY NUMBER PRIMARY KEY,
    FIELD0 VARCHAR2(255), FIELD1 VARCHAR2(255),
    FIELD2 VARCHAR2(255), FIELD3 VARCHAR2(255),
    FIELD4 VARCHAR2(255), FIELD5 VARCHAR2(255),
    FIELD6 VARCHAR2(255), FIELD7 VARCHAR2(255),
    FIELD8 VARCHAR2(255), FIELD9 VARCHAR2(255)
) organization index; 
EOF
}

ycsb_create_dense_table() {
cat <<EOF
CREATE TABLE YCSBDENSE${SIZE_FACTOR_NAME} (
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
    INTO TABLE YCSBSPARSE${SIZE_FACTOR_NAME}
    FIELDS terminated by '|' trailing nullcols
    (
        YCSB_KEY
    )
EOF

    # don't generate logging for batch load
    echo "alter table YCSBSPARSE${SIZE_FACTOR_NAME} nologging;" | cli_user
        
    # load
    sqlldr ${db}/${DB_ARC_PW} \
        control=/tmp/ycsb.ctl.$$ \
        data=/tmp/ycsb.fifo.$$ \
        log=/tmp/ycsb.log.$$ \
        discard=/tmp/ycsb.dsc.$$ \
        direct=y \
        ERRORS=0

    # done.  generate logging
    echo "alter table YCSBSPARSE${SIZE_FACTOR_NAME} logging;" | cli_user

    # show report of the load
    cat /tmp/ycsb.log.$$
    rm /tmp/ycsb*.$$

    set +x
}

ycsb_load_dense_table() {
    
    # boiler plate code
    ycsb_set_param ${*}
    ycsb_create_dense_table | cli_user
    # the real code
    logfile=${LOGDIR}/ycsb_dense.${SIZE_FACTOR}.log.$$
    dscfile=${LOGDIR}/ycsb_dense.${SIZE_FACTOR}.dsc.$$
    ctlfile=${LOGDIR}/ycsb_dense.${SIZE_FACTOR}.ctl.$$
    datafile=${LOGDIR}/ycsb_dense.${SIZE_FACTOR}.fifo.$$

    if [ -f $logfile ]; then echo "$logfile exists. skipping" >&2; return 0; fi

    ycsb_dense_data $datafile   
    # load data statement
    cat <<EOF >${ctlfile}
    LOAD DATA
    INTO TABLE YCSBDENSE${SIZE_FACTOR_NAME}
    FIELDS terminated by ',' trailing nullcols
    ( YCSB_KEY, FIELD0, FIELD1, FIELD2, FIELD3, FIELD4, FIELD5, FIELD6, FIELD7, FIELD8, FIELD9 )
EOF

    # don't generate logging for batch load
    echo "alter table YCSBDENSE${SIZE_FACTOR_NAME} nologging;" | cli_user
        
    # load
    sqlldr ${db}/${DB_ARC_PW} \
        control=${ctlfile} \
        data=${datafile} \
        log=${logfile} \
        discard=${dscfile} \
        direct=y \
        ERRORS=0

    # done.  generate logging
    echo "alter table YCSBDENSE${SIZE_FACTOR_NAME} logging;" | cli_user

    # show report of the load
    cat ${logfile}

    set +x
}

# below is the same of all of the databases

ycsb_set_param() {
    export ROLE=${1}
    export DB_ARC_USER=${2} 
    export DB_ARC_PW=${3} 
    export DB_DB=${4} 
    export SIZE_FACTOR=${5:-1}
    export SIZE_FACTOR_NAME

    if [ "${SIZE_FACTOR}" = "1" ]; then
        SIZE_FACTOR_NAME=""
    else
        SIZE_FACTOR_NAME=${SIZE_FACTOR}
    fi

    db="${USER_PREFIX}${DB_ARC_USER}"
}

ycsb_sparse_data() {
    datafile=$1
    rm $datafile >/dev/null 2>&1
    mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > ${datafile} &
}

ycsb_dense_data() {
    datafile=$1
    rm $datafile >/dev/null 2>&1
    mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR} - 1 )) | \
        awk '{printf "%d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d\n", \
            $1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1}' > ${datafile} &   
}

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
    if [ ! -f ~/03_ycsb.txt ]; then
        time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1 | tee -a ${LOGDIR}/03_ycsb.txt
        # time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10  | tee -a ${LOGDIR}/03_ycsb.txt
        # time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100  | tee -a ${LOGDIR}/03_ycsb.txt
        # time ycsb_load_dense_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1  | tee -a ${LOGDIR}/03_ycsb.txt
    else
        echo "${LOGDIR}/03_ycsb.txt exists. skipping" 
    fi
}

echo "starting $0 with ${*}"
if [ ! -f ${LOGDIR}/03_ycsb.txt ]; then
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then
        create_src
    fi
fi