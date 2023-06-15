#!/usr/bin/env bash

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

ycsb_create_db() {
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

ycsb_load_db() {
    set -x

    datafile=/tmp/ycsb.fifo.$$
    rm  ${datafile} 2>/dev/null
    mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > ${datafile} &
    ycsb_create_db | cli_user

    echo "ALTER INSTANCE DISABLE INNODB REDO_LOG;" | cli_root

    echo "load data local infile '${datafile}' into table THEUSERTABLE${SIZE_FACTOR_NAME} (YCSB_KEY);" | \
        cli_user

    rm ${datafile}

    echo "ALTER INSTANCE ENABLE INNODB REDO_LOG;" | cli_root

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

    db="${DB_ARC_USER}"

    ycsb_load_db
}

create_src() {
    # 1M rows (2MB), 10M (25MB) and 100M (250MB) 1B (2.5G) rows
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10 
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1000
}

(return 0 2>/dev/null) && sourced=1 || sourced=0

if (( sourced != 1 )); then
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then
        create_src
    fi
fi