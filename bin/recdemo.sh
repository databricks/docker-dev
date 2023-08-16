#!/usr/bin/env bash

# s = source
# t = target
# r = real
# s = snapshot
# f = full 
# d = delta
dock_reals=(db2 informix mariadb mysql oraee oraxe pg sqlserver)
dock_fulls="${dock_reals[*]}"
dock_snaps=(cockroach s2 sqledge yugabytesql ${dock_reals[*]})
# ase db2 not supported as a target
dock_dsts=(cockroach informix kafka mariadb minio mysql null oraee oraxe pg redis s2 sqledge sqlserver yugabytesql) 

snow_cdcs=(snowflake)
snow_srcs=(snowflake)
snow_dsts=(snowflake)

gcp_cdcs=(gcsa gcsm gcsp)
gcp_srcs=(gbq gcsa gcsm gcsp)
gcp_dsts=(gbq gcs gcsa gcsm gcsp)

repl_types=(snapshot real-time full)

export RECDEMO_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

. ${RECDEMO_DIR}/startdb.sh

rec_pipeline() {
    local CMD="$1"
    echo docker exec -it arcion-demo-test-workloads-1 bash -c "/scripts/bin/recdemo.sh $CMD"
    docker exec -it arcion-demo-test-workloads-1 bash -c "/scripts/bin/recdemo.sh $CMD"
}

# export ARCDEMO_OPTS="-w 1200"
export ARCDEMO_OPTS=""

docker_compose_db up arcion-demo-test

declare -a "SRC_CSV=( $(echo ${dock_snaps[*]} ${dock_reals[*]} ${dock_fulls[*]} | xargs -n1 | sort -u ))"
declare -a "DST_CSV=( $(echo ${dock_dsts[*]} | xargs -n1 | sort -u ))"
declare -A "SNAP_DICT=( $(echo ${dock_snaps[@]} | sed 's/[^ ]*/[&]=&/g') )"
declare -A "REAL_DICT=( $(echo ${dock_reals[@]} | sed 's/[^ ]*/[&]=&/g') )"
declare -A "FULL_DICT=( $(echo ${dock_fulls[@]} | sed 's/[^ ]*/[&]=&/g') )"

declare -p SRC_CSV
declare -p DST_CSV
declare -p SNAP_DICT
declare -p REAL_DICT
declare -p FULL_DICT

for src in "${SRC_CSV[@]}"; do
    echo start_db "$src" 
    start_db "$src" 

    for tgt in "${DST_CSV[@]}"; do
        echo "  start_db $tgt" 
        start_db "$tgt" 

        for repl_type in "${repl_types[@]}"; do
            case ${repl_type} in 
                snapshot)
                    if [ -z "${SNAP_DICT[$src]}" ]; then
                        echo "    $src $tgt $repl_type: not supported"
                        continue
                    fi 
                    CMD="arcdemo.sh -w 300 $repl_type $src $tgt"
                    ;;
                real-time) 
                    if [ -z "${REAL_DICT[$src]}" ]; then
                        echo "    $src $tgt $repl_type: not supported"
                        continue
                    fi
                    CMD="arcdemo.sh -w 300:300 -r 0 $repl_type $src $tgt"
                    ;;
                full) 
                    if [ -z "${REAL_DICT[$src]}" ]; then
                        echo "    $src $tgt $repl_type: not supported"
                        continue
                    fi
                    CMD="arcdemo.sh -w 300:300 -r 0 $repl_type $src $tgt"
                    ;;
                *) echo "    ${repl_type} not handled.  skipping"
                    continue 
                    ;;
            esac
            
            # DEBUG: 
            #sleep 1
            echo "    rec_pipeline $CMD"
            rec_pipeline "$CMD"
        done
        echo "  stop_db $tgt" 
        stop_db "$tgt" 
    done
    echo "stop_db $src" 
    stop_db "$src" 
done

declare -p ACTIVE_DB