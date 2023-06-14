#!/usr/bin/env bash

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

    rm /tmp/ycsb.fifo.$$ 2>/dev/null
    mkfifo /tmp/ycsb.fifo.$$
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > /tmp/ycsb.fifo.$$ &
    ycsb_create_db | mysql -u ${db} --password=${DB_ARC_PW} -D ${db}

    echo "load data local infile '/tmp/ycsb.fifo.$$' into table THEUSERTABLE${SIZE_FACTOR_NAME} (YCSB_KEY);" | \
        mysql -u ${db} \
            --password=${DB_ARC_PW} \
            -D ${db} \
            --local-infile
    rm /tmp/ycsb.fifo.$$

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
    if [ -z "${ARCDEMO_DEBUG}" ]; then
        ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100
    fi
}

if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then
    create_src
fi
