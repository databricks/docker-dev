#!/usr/bin/env bash

# change below for each database

cli_user() {
    # refer to https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
    # "${*@Q}" preserves quotes
    export PGPASSWORD=${db} 
    psql --username "${DB_ARC_PW}" --dbname "${db}"
}

cli_root() {
    psql --username "$POSTGRES_USER"
}

db_disable_logging() {
    echo ""
}

db_enable_logging() {
    echo ""
}

ycsb_create_sparse_table() {
cat <<EOF
CREATE TABLE IF NOT EXISTS THEUSERTABLE${SIZE_FACTOR_NAME} (
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
CREATE TABLE IF NOT EXISTS DENSETABLE${SIZE_FACTOR_NAME} (
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
    ycsb_create_sparse_table | psql --username "${db}" --dbname "${db}"
    # the real code

    datafile=/tmp/ycsb_sparse.${SIZE_FACTOR}.fifo.$$
    ycsb_sparse_data $datafile
    
    export PGPASSWORD=${DB_ARC_PW}
    set -x
    cat ${datafile} |  psql --username "${db}" --dbname "${db}" -c "copy THEUSERTABLE${SIZE_FACTOR_NAME} (ycsb_key) from STDIN"
    set +x
}

ycsb_load_dense_table() {    
    
    # boiler plate code
    ycsb_set_param ${*}
    ycsb_create_dense_table | psql --username "${db}" --dbname "${db}"
    # the real code

    datafile=/tmp/ycsb_dense.${SIZE_FACTOR}.fifo.$$
    ycsb_dense_data $datafile      

    export PGPASSWORD=${DB_ARC_PW}
    set -x
    cat ${datafile} | psql --username "${db}" --dbname "${db}" -c "copy DENSETABLE${SIZE_FACTOR_NAME} (ycsb_key,field0,field1,field2,field3,field4,field5,field6,field7,field8,field9) from STDIN DELIMITER ','"
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

    time ycsb_load_sparse_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1
    time ycsb_load_sparse_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10
    time ycsb_load_sparse_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100
    time ycsb_load_dense_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1
    time ycsb_load_dense_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10

    db_enable_logging
    ycsb_rm_data
}

# pass argument to to not run (mainly for testing)
if [[ -z "${1}" ]]; then
    if [ ! -f ${LOGDIR}/03_ycsb.txt ]; then
        if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then ROLE=SRC; else ROLE=DST; fi

        if [[ "${ROLE^^}" = "SRC" ]]; then
            create_src | tee -a ${LOGDIR}/02_ycsb.txt
        fi
    fi
fi