#!/usr/bin/env bash

ycsb_create_singlestore() {
cat <<'EOF'
CREATE TABLE IF NOT EXISTS THEUSERTABLE (
    YCSB_KEY INT,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT,
    TS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    KEY (YCSB_KEY) USING HASH,
    SORT KEY (TS),
    SHARD KEY (YCSB_KEY)
);
EOF
}

ycsb_load() {
    local ROLE=${1}
    local DB_ARC_USER=${2} 
    local DB_ARC_PW=${3} 
    local DB_DB=${4} 
    local SIZE_FACTOR=${5}
    set -x

    rm /tmp/ycsb.fifo.$$ 2>/dev/null
    mkfifo /tmp/ycsb.fifo.$$
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > /tmp/ycsb.fifo.$$ &
    ycsb_create_singlestore | singlestore -u ${DB_ARC_USER}${SIZE_FACTOR} --password=${DB_ARC_PW} -D ${DB_DB}${SIZE_FACTOR} --init-command="use ${DB_DB}${SIZE_FACTOR};"

    # singlestore -D and --database does not switch database
    echo "load data local infile '/tmp/ycsb.fifo.$$' into table THEUSERTABLE (YCSB_KEY);" | \
        singlestore -u ${DB_ARC_USER}${SIZE_FACTOR} \
            --password=${DB_ARC_PW} \
            -D ${DB_DB}${SIZE_FACTOR} \
            --local-infile \
             --init-command="use ${DB_DB}${SIZE_FACTOR};"
    rm /tmp/ycsb.fifo.$$

    set +x
}
# 1M rows (2MB), 10M (25MB) and 100M (250MB) 1B (2.5G) rows
ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB}  
if [ -z "${ARCDEMO_DEBUG}" ]; then
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 10 
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 100
fi
