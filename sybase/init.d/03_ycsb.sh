#!/usr/bin/env bash

# https://learn.microsoft.com/en-us/sql/tools/bcp-utility?view=sql-server-ver16
# does not support pipe

PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
. ${PROG_DIR}/utils.sh

load_dense_data() {
    local SIZE_FACTOR=${1:-${SIZE_FACTOR:-1}}
    local SIZE_FACTOR_NAME=$(sf_to_name $SIZE_FACTOR)
    echo "Starting dense table $SIZE_FACTOR" 

    # create table
    heredoc_file ${PROG_DIR}/lib/03_densetable.sql | tee ${INITDB_LOG_DIR}/03_densetable.sql 
    cli_arcsrc < ${INITDB_LOG_DIR}/03_densetable.sql 

    # prepare bulk loader
    heredoc_file ${PROG_DIR}/lib/03_densetable.fmt | tee ${INITDB_LOG_DIR}/03_densetable.fmt

    # prepare data file
    datafile=$(mktemp)
    ycsb_dense_data $datafile ${SIZE_FACTOR}
    
    # run the bulk loader
    # batch of 1M
    time bcp DENSETABLE${SIZE_FACTOR_NAME} in "$datafile" -Uarcsrc -PPassw0rd -S $SYBASE_SID -f ${INITDB_LOG_DIR}/03_densetable.fmt -b 10000 
    # 2>&1 | tee ${INITDB_LOG_DIR}/03_densetable.log

    # delete datafile
    rm -rf $datafile

    echo "Finished dense table $SIZE_FACTOR" 
}

load_sparse_data() {
    local SIZE_FACTOR=${1:-${SIZE_FACTOR:-1}}
    local SIZE_FACTOR_NAME=$(sf_to_name $SIZE_FACTOR)
    echo "Starting sparse table $SIZE_FACTOR" 

    # create table
    heredoc_file ${PROG_DIR}/lib/03_sparsetable.sql | tee ${INITDB_LOG_DIR}/03_sparsetable.sql 
    cli_arcsrc < ${INITDB_LOG_DIR}/03_sparsetable.sql 

    # prepare bulk loader
    heredoc_file ${PROG_DIR}/lib/03_sparsetable.fmt | tee ${INITDB_LOG_DIR}/03_sparsetable.fmt

    # prepare data file
    #datafile=/tmp/tmp.WLkdsbnc2m #$(mktemp)
    datafile=$(mktemp)
    ycsb_sparse_data $datafile ${SIZE_FACTOR}
    
    # run the bulk loader
    # batch of 1M
    time bcp THEUSERTABLE${SIZE_FACTOR_NAME} in "$datafile" -Uarcsrc -PPassw0rd -S $SYBASE_SID -f ${INITDB_LOG_DIR}/03_sparsetable.fmt -b 100000 
    # 2>&1 | tee ${INITDB_LOG_DIR}/03_sparsetable.log

    # delete datafile
    #rm -rf $datafile   

    echo "Finished sparse table $SIZE_FACTOR" 
}

ycsb_sparse_data() {
    local datafile=${1:-$(mktemp)}
    local SIZE_FACTOR=${2:-${SIZE_FACTOR:-1}}

    rm -rf $datafile >/dev/null 2>&1
    #mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) > ${datafile}
}

ycsb_dense_data() {
    local datafile=${1:-$(mktemp)}
    local SIZE_FACTOR=${2:-${SIZE_FACTOR:-1}}

    rm -rf $datafile >/dev/null 2>&1
    #mkfifo ${datafile}
    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) | \
        awk '{printf "%10d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d,%0100d\n", \
            $1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1}' > ${datafile}
}

if [[ $(uname -a | awk '{print $2}') =~ 'src' ]]; then ROLE=SRC; else ROLE=DST; fi

if [ -f ${INITDB_LOG_DIR}/03_ycsb.txt ]; then
    echo "$0: skipping. found ${INITDB_LOG_DIR}/03_ycsb.txt"
else

    if [[ "${ROLE^^}" = "SRC" ]]; then

        load_sparse_data 1
        load_sparse_data 10
        load_sparse_data 100
        #load_sparse_data 1000
        load_dense_data 1
    fi
    touch ${INITDB_LOG_DIR}/03_ycsb.txt
fi