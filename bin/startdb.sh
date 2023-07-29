#!/usr/bin/env bash

export STARTDB_DIR=$(pwd)/$(dirname ${BASH_SOURCE[0]})
DBS=(arcion-demo-test
    ase
    cockroach
    db2
    informix
    kafka
    mariadb
    minio
    mysql
    pg
    redis
    s2
    sqledge
    sqlserver
    oraee
    oraxe
    yugabyte
    )

# return single line of docker ps
# mysql paused 1 /abc/def/xyz
run_docker_compose_ls() {
    local d=${d:-$1}
    docker compose ls --filter "name=$d" \
        | tail -n +2 \
        | awk -F'[[:space:]]+' '{print $1 "," $2 "," $3}' \
        | awk -F'[(),]' '{printf "%s,%s,%s,%s",$1,$2,$3,$5}'
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

    pushd ../$d || return 1
    run_docker_compose $1 $2
    popd    
}

docker_compose_ora() {
    local cmd=${1}
    local d=${d:-${2}}

    pushd ../oracle/$d || return 1
    run_docker_compose $1 $2
    popd
}

# yb does not come back up 
docker_compose_yb() {
    local cmd=${1}
    local d=${d:-${2}}

    pushd ../$d || return 1
    case ${cmd} in up|unpause|restart|start) docker compose down -v;; esac   
    run_docker_compose $1 $2
    popd
}

# run docker compose cmd database
docker_compose_db() {
    local cmd=${1}
    local d=${2}

    if [ -z "${d}" ]; then 
        echo "specify database" && return 1
    fi

    pushd $STARTDB_DIR || return 1
    case ${d} in 
        yugabyte) docker_compose_yb $1 $2;;
        oraxe|oraee) docker_compose_ora $1 $2;;
        *) docker_compose_others $1 $2;;
    esac
    popd 
}