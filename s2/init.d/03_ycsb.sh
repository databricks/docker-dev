#!/usr/bin/env bash

ycsb_create_deltatable() {
cat <<EOF
-- initial population has YCSB_KEY + dates 
CREATE TABLE IF NOT EXISTS DELTATABLE${SIZE_FACTOR_NAME} (
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
ycsb_create_usertable() {
cat <<EOF
-- initial population has YCSB_KEY + repeating data for better compression 
CREATE TABLE IF NOT EXISTS YCSBSPARSE${SIZE_FACTOR_NAME} (
    YCSB_KEY INT,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT,
    KEY (YCSB_KEY) USING HASH,
    SHARD KEY (YCSB_KEY)
);
EOF
}


ycsb_load_deltatable() {
set -x
if [ ! -f ~/ycsb_load_deltatable_${SIZE_FACTOR_NAME} ]; then
    # --init-command="use ${DB_DB};"
    # singlestore -D and --database options do not switch database
    ycsb_create_deltatable | singlestore -u ${db} --password=${DB_ARC_PW} -D ${db} --init-command="use ${db};"

    rm /tmp/deltatable.fifo.$$ 2>/dev/null
    mkfifo /tmp/deltatable.fifo.$$
    seq 0 $(( 1000000*${SIZE_FACTOR} - 1 )) > /tmp/deltatable.fifo.$$ &

    echo "load data local infile '/tmp/deltatable.fifo.$$' into table DELTATABLE${SIZE_FACTOR_NAME} (YCSB_KEY);" | \
        singlestore -f -u ${db} \
            --password=${DB_ARC_PW} \
            -D ${db} \
            --local-infile \
             --init-command="use ${db};"
    rm /tmp/deltatable.fifo.$$
    touch ~/ycsb_load_deltatable_${SIZE_FACTOR_NAME}.done
fi
set +x
}

ycsb_load_usertable() {
set -x
if [ ! -f ~/ycsb_load_usertable_${SIZE_FACTOR_NAME} ]; then

    if (( SIZE_FACTOR > 100 )); then echo "skipping YCSBSPARSE${SIZE_FACTOR_NAME}"; return 0; fi

    set -x
    # --init-command="use ${DB_DB};"
    # singlestore -D and --database options do not switch database
    ycsb_create_usertable | singlestore -u ${db} --password=${DB_ARC_PW} -D ${db} --init-command="use ${db};"

    rm /tmp/usertable.fifo.$$ 2>/dev/null
    mkfifo /tmp/usertable.fifo.$$
    seq 0 $(( 1000000*${SIZE_FACTOR} - 1 )) | \
        awk '{printf "%d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d\n", \
            $1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1}' > /tmp/usertable.fifo.$$ &

    echo "load data local infile '/tmp/usertable.fifo.$$' into table YCSBSPARSE${SIZE_FACTOR_NAME} \
        (YCSB_KEY,FIELD0,FIELD1,FIELD2,FIELD3,FIELD4,FIELD5,FIELD6,FIELD7,FIELD8,FIELD9) \
        fields terminated by ',';" | \
        singlestore -f -u ${db} \
            --password=${DB_ARC_PW} \
            -D ${db} \
            --local-infile \
             --init-command="use ${db};"
    rm /tmp/usertable.fifo.$$
    touch ~/ycsb_load_usertable_${SIZE_FACTOR_NAME}.done
fi
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

    ycsb_load_deltatable &
    if [[ -z "${ARCDEMO_DEBUG}" ]] && (( SIZE_FACTOR < 100 )); then
        ycsb_load_usertable &
    fi
    wait
}

create_src() {
    # compressed size for deltatable (real size will be 10x)
    # 1M rows (2MB), 10M (25MB) and 100M (250MB) 1B (2.5G) rows

    # compressed size for usertable (real size will be 10x)
    # 1M rows (159MB), 10M (1.6G) and 100M (16.9GB) 
    
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10 
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100
    if [ -z "${ARCDEMO_DEBUG}" ]; then
        ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1000
    fi
}

if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then
    create_src
fi
