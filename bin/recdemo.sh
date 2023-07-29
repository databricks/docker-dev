#!/usr/bin/env bash

export RECDEMO_DIR=$(pwd)/$(dirname ${BASH_SOURCE[0]})

. ${RECDEMO_DIR}/startdb.sh

rec_pipeline() {
    RECFILENAME=${REPL_TYPE}_${SOURCE}_${DESTINATION}.ascii.cast
    RECFILE=${REC_DIR}/${RECFILENAME}
    echo ${REPL_TYPE} ${SOURCE} ${DESTINATION} $RECFILE
    STARTTIME=$(date +%s)
    ./recdemo.expect
    ENDTIME=$(date +%s)
    # save duration
    DURATION=$((ENDTIME-STARTTIME))
    # wait for CDC to finish
    sleep 10 
    clear
     # remove the trailing \n with < <()
     # clear is there to remove garbage from tmux and expect interactions
    docker exec -it arcion-demo-test-workloads-1 bash -c "clear"
    readarray -d' ' -t LOG_ID < <(docker exec -it arcion-demo-test-workloads-1 bash -c ". /tmp/ini_menu.sh; echo -n \$(basename \$CFG_DIR) \$LOG_ID")
    # save the record
    echo ${REPL_TYPE},${SOURCE},${DESTINATION},$DURATION,$RECFILENAME,${LOG_ID[0]},${LOG_ID[1]} | tee -a $REC_DIR/clivideo.csv
}

export REC_DIR=~/github/arcion/demokit.gtihub-io/docs/resources/asciinema
export REPL_TYPES=(snapshot)
export SOURCES=(s2) # db2 informix mysql oraee pg s2 sqlserver sqledge)
export DESTINATIONS=(ase
cockroach
db2
informix
kafka
mariadb
minio
mysql
null
oraee
pg
redis
s2
snowflake
sqledge
sqlserver
yugabyte)

export REPL_TYPE
export SOURCE
export DESTINATION
export RECFILE

mkdir -p $REC_DIR

DEST_LEN=${#DESTINATIONS[@]}
# start source 
# start destination
for REPL_TYPE in "${REPL_TYPES[@]}"; do
    for SOURCE in "${SOURCES[@]}"; do
    start_db $SOURCE
    for D_I in $(seq 0 $(($DEST_LEN - 1)) ); do
        # rec_pipeline
        DESTINATION=${DESTINATIONS[$D_I]}
        echo ${REPL_TYPE},${SOURCE},${DESTINATION}
    done
    stop_db $SOURCE
done
done