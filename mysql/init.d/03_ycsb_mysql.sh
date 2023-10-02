#!/usr/bin/env bash

# change below for each database

cli_user() {
    mysql -u ${db} \
        --password=${DB_ARC_PW} \
        -D ${db} \
        --local-infile    
}

cli_root() {
    mysql -u root \
        --password=${MYSQL_ROOT_PASSWORD}
}

db_disable_logging() {
    set -x
    echo "ALTER INSTANCE DISABLE INNODB REDO_LOG;" #| cli_root
    set +x
}

db_enable_logging() {
    set -x
    echo "ALTER INSTANCE ENABLE INNODB REDO_LOG;" #| cli_root
    set +x
}

ycsb_create_sparse_table() {
cat <<EOF
CREATE TABLE IF NOT EXISTS YCSBSPARSE${SIZE_FACTOR_NAME} (
    YCSB_KEY INT PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT
);
EOF
}

ycsb_create_dense_table() {
cat <<EOF
CREATE TABLE IF NOT EXISTS YCSBDENSE${SIZE_FACTOR_NAME} (
    YCSB_KEY INT PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT
);
EOF
}

ycsb_load_sparse_table() {

    # boiler plate code
    ycsb_set_param ${*}
    ycsb_create_sparse_table | cli_user
    # the real code

    datafile=/tmp/ycsb_sparse.${SIZE_FACTOR}.fifo.$$
    ycsb_sparse_data $datafile
    
    set -x
    echo "load data local infile '${datafile}' into table YCSBSPARSE${SIZE_FACTOR_NAME} (YCSB_KEY);" | \
        cli_user
    set +x
}

ycsb_load_dense_table() {    
    
    # boiler plate code
    ycsb_set_param ${*}
    ycsb_create_dense_table | cli_user
    # the real code

    datafile=/tmp/ycsb_dense.${SIZE_FACTOR}.fifo.$$
    ycsb_dense_data $datafile      

    set -x
    echo "load data local infile '${datafile}' into table YCSBDENSE${SIZE_FACTOR_NAME} (YCSB_KEY);" | \
        cli_user
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

    db="${DB_ARC_USER}"
}

ycsb_rm_data() {
    rm /tmp/ycsb_*.fifo.* 2>/dev/null    
}

ycsb_sparse_data() {
    datafile=$1
    mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > ${datafile} &
}

ycsb_dense_data() {
    datafile=$1
    mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR} - 1 )) | \
        awk '{printf "%d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d\n", \
            $1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1}' > ${datafile} &   
}

create_src() {
    # 1M rows (2MB), 10M (25MB) and 100M (250MB) 1B (2.5G) rows
    ycsb_rm_data
    db_disable_logging

    time ycsb_load_sparse_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1 | tee -a ~/03_ycsb.txt
    time ycsb_load_sparse_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10 | tee -a ~/03_ycsb.txt
    # time ycsb_load_sparse_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100 | tee -a ~/03_ycsb.txt
    time ycsb_load_dense_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1 | tee -a ~/03_ycsb.txt
    # time ycsb_load_dense_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10 | tee -a ~/03_ycsb.txt

    db_enable_logging
    ycsb_rm_data
}

echo "starting $0 with ${*}"
if [[ -z "${1}" ]]; then
    if [ ! -f ${LOGDIR}/03_ycsb.txt ]; then
        if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then ROLE=SRC; else ROLE=DST; fi

        if [[ "${ROLE^^}" = "SRC" ]]; then
            create_src 2>&1 | tee -a ${LOGDIR}/03_ycsb.txt
        fi
    fi
fi