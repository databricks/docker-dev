#!/usr/bin/env bash

ycsb_create_oracle() {
cat <<'EOF'
CREATE TABLE THEUSERTABLE (
    YCSB_KEY NUMBER PRIMARY KEY,
    FIELD0 VARCHAR2(255), FIELD1 VARCHAR2(255),
    FIELD2 VARCHAR2(255), FIELD3 VARCHAR2(255),
    FIELD4 VARCHAR2(255), FIELD5 VARCHAR2(255),
    FIELD6 VARCHAR2(255), FIELD7 VARCHAR2(255),
    FIELD8 VARCHAR2(255), FIELD9 VARCHAR2(255),
    TS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
); 
CREATE INDEX THEUSERTABLE_TS ON THEUSERTABLE (TS);
EOF
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
    DB_ARC_USER=C##${DB_ARC_USER}${SIZE_FACTOR_NAME}

    set -x

    db="${DB_ARC_USER}_${DB_DB}"

    ycsb_create_oracle | sqlplus ${db}/${DB_ARC_PW} 

    # setup name pipe for the table
    rm /tmp/ycsb.fifo.$$ 2>/dev/null
    mkfifo /tmp/ycsb.fifo.$$
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > /tmp/ycsb.fifo.$$ &
    
    # load data statement
    cat <<EOF >/tmp/ycsb.ctl.$$
    LOAD DATA
    truncate
    INTO TABLE THEUSERTABLE
    FIELDS terminated by '|' trailing nullcols
    (
        YCSB_KEY
    )
EOF

    # don't generate logging for batch load
    echo "alter table THEUSERTABLE nologging;" | \
        sqlplus ${db}/${DB_ARC_PW} 

    # load
    sqlldr ${db}/${DB_ARC_PW} \
        control=/tmp/ycsb.ctl.$$ \
        data=/tmp/ycsb.fifo.$$ \
        log=/tmp/ycsb.log.$$ \
        discard=/tmp/ycsb.dsc.$$ \
        direct=y \
        ERRORS=0

    # done.  generate logging
    echo "alter table THEUSERTABLE logging;" | \
    sqlplus ${db}/${DB_ARC_PW} 

    # show report of the load
    cat /tmp/ycsb.log.$$
    rm /tmp/ycsb*.$$

    set +x
}

create_src() {
    # 1M rows (2MB), 10M (25MB) and 100M (250MB) 1B (2.5G) rows
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1

    if [ -z "${ARCDEMO_DEBUG}" ]; then
        ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10 
        ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100
    fi
}

if [[ $(hostname) =~ src$ ]]; then
    create_src
fi
