#!/usr/bin/env bash

export STARTDB_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# return single line of docker ps
# mysql paused 1 /abc/def/xyz
run_docker_compose_ls() {
    local d=${d:-$1}
    local filter
    if [ -n "${d}" ]; then filter="--filter name=$d"; fi
    docker compose ls $filter \
        | tail -n +2 \
        | awk -F'[[:space:]]+' '{print $1 "," $2 "," $3}' \
        | awk -F'[(),]' '{printf "%s%s,%s,%s,%s",NEWLINE,$1,$2,$3,$5;NEWLINE="\n"}'
}

# have up handle paused vs stopped
run_docker_compose() {
    local cmd=${1:-start}
    local d=${d:-${2}}
    
    readarray -d',' -t DOCKER_LS < <(run_docker_compose_ls $d)
    case ${cmd} in 
        up) if [[ "${DOCKER_LS[1]}" = "paused" ]]; then docker compose unpause; 
            else docker compose up -d; fi
            ;;
        *) docker compose $cmd
            ;;
    esac
}


# will be inside the bin dir
# $1=start|pause|unpause
# $2=dirname ie mysql|mariadb|..
docker_compose_others() {
    local cmd=${1:-start}
    local d=${d:-${2}}
    local WAIT_TO_COMPLETE=${3}

    if [ ! -d ../$d ] || [ ! -f ../$d/docker-compose.yaml ];then return 1; fi

    pushd ../$d >/dev/null || return 1
    run_docker_compose $1 $2
    if [ -n "$WAIT_TO_COMPLETE" ]; then 
        $WAIT_TO_COMPLETE
    fi
    popd >/dev/null   
}

docker_compose_ora() {
    local cmd=${1}
    local d=${d:-${2}}
    local WAIT_TO_COMPLETE=${3}

    pushd ../oracle/$d >/dev/null || return 1
    run_docker_compose $1 $2
    if [ -n "$WAIT_TO_COMPLETE" ]; then 
        $WAIT_TO_COMPLETE
    fi
    popd >/dev/null
}

# yb does not come back up 
docker_compose_yb() {
    local cmd=${1}
    local d=${d:-${2}}
    local WAIT_TO_COMPLETE=${3}

    pushd ../$d >/dev/null || return 1
    case ${cmd} in up|unpause|restart|start) docker compose down -v;; esac   
    run_docker_compose $1 $2
    if [ -n "$WAIT_TO_COMPLETE" ]; then 
        $WAIT_TO_COMPLETE
    fi
    popd >/dev/null
}

wait_arcion_demo() {
    ttyd_started=$( docker compose logs workloads | grep ttyd )
    while [ -z "${ttyd_started}" ]; do
        sleep 1
        echo "waiting on docker compose logs workloads | grep ttyd"
        ttyd_started=$( docker compose logs workloads | grep ttyd )
    done
}

# run docker compose cmd database
docker_compose_db() {
    local cmd=${1}
    local d=${2}

    if [ -z "${d}" ] || [ -z "${cmd}" ]; then 
        echo "specify \$1=cmd (up|pause) and \$2=database" >&2 && return 1
    fi

    pushd $STARTDB_DIR >/dev/null || return 1
    case ${d} in 
        arcion-demo|arcion-demo-test) docker_compose_others "$1" "$2" "wait_arcion_demo";;
        kafka|yugabyte) docker_compose_yb "$1" "$2";;
        oraxe|oraee) docker_compose_ora "$1" "$2";;
        *) docker_compose_others "$1" "$2";;
    esac
    popd >/dev/null
}
