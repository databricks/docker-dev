#!/usr/bin/env bash

export USER_PREFIX=c##

cli_user() {
    echo sqlplus ${db}/${DB_ARC_PW}@${ORACLE_SID} >&2
    sqlplus ${db}/${DB_ARC_PW}@${ORACLE_SID}    
}

cli_root() {
    isql -U $SYBASE_ROOT -P  $SYBASE_PASSWORD -S $SYBASE_SID 
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

ycsb_create_dense_table() {
cat <<EOF
CREATE TABLE DENSETABLE${SIZE_FACTOR_NAME} (
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

ycsb_load_dense_table() {
    
    # boiler plate code
    ycsb_set_param ${*}
    ycsb_create_dense_table | cli_user
    # the real code
    logfile=~/ycsb_dense.${SIZE_FACTOR}.log.$$
    dscfile=~/ycsb_dense.${SIZE_FACTOR}.dsc.$$
    ctlfile=~/ycsb_dense.${SIZE_FACTOR}.ctl.$$
    datafile=~/ycsb_dense.${SIZE_FACTOR}.fifo.$$

    if [ -f $logfile ]; then echo "$logfile exists. skipping" >&2; return 0; fi

    ycsb_dense_data $datafile   
    # load data statement
    cat <<EOF >${ctlfile}
    LOAD DATA
    INTO TABLE DENSETABLE${SIZE_FACTOR_NAME}
    FIELDS terminated by ',' trailing nullcols
    ( YCSB_KEY, FIELD0, FIELD1, FIELD2, FIELD3, FIELD4, FIELD5, FIELD6, FIELD7, FIELD8, FIELD9 )
EOF

    # don't generate logging for batch load
    echo "alter table DENSETABLE${SIZE_FACTOR_NAME} nologging;" | cli_user
        
    # load
    sqlldr ${db}/${DB_ARC_PW} \
        control=${ctlfile} \
        data=${datafile} \
        log=${logfile} \
        discard=${dscfile} \
        direct=y \
        ERRORS=0

    # done.  generate logging
    echo "alter table DENSETABLE${SIZE_FACTOR_NAME} logging;" | cli_user

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
    rm -rf $datafile >/dev/null 2>&1
    mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > ${datafile} &
}

ycsb_dense_data() {
    datafile=$1
    rm -rf $datafile >/dev/null 2>&1
    mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) | \
        awk '{printf "%10d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d\n", \
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
        time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1 | tee -a ~/03_ycsb.txt
        time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 10  | tee -a ~/03_ycsb.txt
        time ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 100  | tee -a ~/03_ycsb.txt
        time ycsb_load_dense_table SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ycsb 1  | tee -a ~/03_ycsb.txt
    else
        echo "~/03_ycsb.txt exists. skipping" 
    fi
}

echo "starting $0 with ${*}"
if [ ! -f ~/03_ycsb.txt ]; then
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then
        create_src
    fi
fi

isql -Uarcsrc -PPassw0rd -SMYSYBASE

for iq only
transfer table THEUSERTABLE from '/tmp/ycsb' for ase

-- https://infocenter.sybase.com/help/topic/com.sybase.infocenter.dc30191.1570/pdf/utilityguide.pdf


https://infocenter.sybase.com/help/index.jsp?topic=/com.sybase.infocenter.dc30191.1570/html/utilityguide/utilityguide86.htm
copy in data with fast bcp
sp_dboption master 'select into/bulkcopy/pllsort' enable

use arcsrc
go
master..sp_dboption arcsrc, 'select into/bulkcopy/pllsort', true
go

-- fix The 16K memory pool of named cache default data cache 
-- https://infocenter-archive.sybase.com/help/index.jsp?topic=/com.sybase.help.ase_15.0.sag2/html/sag2/sag293.htm

sp_cacheconfig "default data cache", "25M"



bcp is an utility
bcp THEUSERTABLE in '/tmp/ycsb' -Uarcsrc -PPassw0rd -S MYSYBASE -f bcp.fmt
default batch is 1,000 lines
-b 10000

-- https://infocenter.sybase.com/help/index.jsp?topic=/com.sybase.infocenter.dc30191.1570/html/utilityguide/utilityguide86.htm
-- https://stackoverflow.com/questions/42044365/how-to-import-csv-file-into-sybasease-with-less-columns-than-table-field-by-usin
command refernce
-- https://infocenter.sybase.com/help/index.jsp?topic=/com.sybase.infocenter.dc30191.1570/html/utilityguide/utilityguide86.htm

for densetable
[root@sybase home]# cat bcp.fmt 
10.0
11
1       SYBCHAR 0       10      ","     1       YCSB_KEY
2       SYBCHAR 0       100     ","     2       FIELD0
3       SYBCHAR 0       100     ","     3       FIELD1
4       SYBCHAR 0       100     ","     4       FIELD2
5       SYBCHAR 0       100     ","     5       FIELD3
6       SYBCHAR 0       100     ","     6       FIELD4
7       SYBCHAR 0       100     ","     7       FIELD5
8       SYBCHAR 0       100     ","     8       FIELD6
9       SYBCHAR 0       100     ","     9       FIELD7
10      SYBCHAR 0       100     ","     10      FIELD8
11      SYBCHAR 0       100     "\n"    11      FIELD9

bcp THEUSERTABLE in '/tmp/ycsb' -Uarcsrc -PPassw0rd -S MYSYBASE -f bcp.fmt -b 100000

for sparse table?
