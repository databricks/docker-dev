#!/usr/bin/env bash

export REC_DIR=~/github/arcion/demokit.gtihub-io/docs/resources/asciinema
export REPL_TYPES=(snapshot)
export SOURCES=(db2 informix mysql oraee pg s2 sqlserver sqledge)
export DESTINATIONS=(null minio cockroach s2 sqlserver)

export REPL_TYPE
export SOURCE
export DESTINATION
export RECFILE

mkdir -p $REC_DIR

for REPL_TYPE in "${REPL_TYPES[@]}"; do
for SOURCE in "${SOURCES[@]}"; do
for DESTINATION in "${DESTINATIONS[@]}"; do
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
 

done
done
done