#!/usr/bin/env bash

export RECDEMO_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

. ${RECDEMO_DIR}/startdb.sh


rec_pipeline() {
    export REPL_TYPE=$1
    export SOURCE=$2
    export TARGET=$3

    RECFILENAME=${REPL_TYPE}_${SOURCE}_${TARGET}.ascii.cast
    export RECFILE=${REC_DIR}/${RECFILENAME}

    echo ${REPL_TYPE} ${SOURCE} ${TARGET} $RECFILE

    STARTTIME=$(date +%s)
    ${RECDEMO_DIR}/recdemo.expect
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
    echo ${REPL_TYPE},${SOURCE},${TARGET},$DURATION,$RECFILENAME,${LOG_ID[0]},${LOG_ID[1]} | tee -a $REC_DIR/clivideo.csv
}

start_db() {
    local -n start_db_active_db=$1
    local db=$2

    echo "$db starting" 
    start_db_active_db[$db]=$(( start_db_active_db[$db] + 1 ))
    docker_compose_db up "$db"
}

stop_db() {
    local -n stop_db_active_db=$1
    local db=$2

    stop_db_active_db[$db]=$(( stop_db_active_db[$db] - 1 ))
    if (( ${stop_db_active_db[$db]} <= 0 )); then 
        echo "$db pausing" 
        docker_compose_db pause "$db"
    else
        echo "$db leaving up" 
    fi
}

export REC_DIR=~/github/arcion/demokit.gtihub-io/docs/resources/asciinema
export REPL_TYPES=(snapshot)
export SOURCES=(db2 informix mysql oraee pg) # db2 informix mysql oraee pg s2 sqlserver sqledge)
export TARGETS=(informix kafka mariadb mysql oracle pg redis sqledge yugabytesql)
# other iterations
#   (db2 informix kafka mariadb)
#   (kafka mysql oraee pg redis sqledge yugabytesql) 
#   (cockroach informix kafka mariadb minio mysql null oraee pg redis s2 sqledge sqlserver yugabytesql)

#
# export ARCDEMO_OPTS="-w 1200"
export ARCDEMO_OPTS=""

# Targets that do not work
# ase db2

mkdir -p $REC_DIR

declare -A ACTIVE_DB=()

docker_compose_db up arcion-demo-test

for REPL_TYPE in "${REPL_TYPES[@]}"; do

    for src in "${SOURCES[@]}"; do

        start_db ACTIVE_DB "$src" 

        for tgt in "${TARGETS[@]}"; do

            start_db ACTIVE_DB "$tgt" 
            echo "${REPL_TYPE},${src},${tgt}"
            docker compose ls | grep running

            # DEBUG: 
            sleep 1
            rec_pipeline "$REPL_TYPE" "$src" "$tgt"

            #wait # wait for previous start_db to complete
            stop_db ACTIVE_DB "$tgt" 
        done

        stop_db ACTIVE_DB "$src" 
    done
done

declare -p ACTIVE_DB