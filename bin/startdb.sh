#!/usr/bin/env bash

# global variables for this script
declare -A ACTIVE_DB=()

export STARTDB_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export DOCKERDEV_DIR="$(dirname $STARTDB_DIR)"

set_machine() {
    export MACHINE=$(uname -p)    
}

install_oraxe() {
    if [[ "${MACHINE}" != "x86_64" ]]; then 
        echo "INFO: Oracle not supported on machine architecture: ${MACHINE}"  
        return 1
    fi    

    local found=$(docker images -q "oracle/database:21.3.0-xe")
    if [[ -z "${found}" ]]; then 

        pushd oracle || exit 
        if [ ! -d oracle-docker-images ]; then
            git clone https://github.com/oracle/docker-images oracle-docker-images
        fi

        cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
        ./buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'
        popd    
    fi
}

install_orafree() {
    if [[ "${MACHINE}" != "x86_64" ]]; then 
        echo "INFO: Oracle not supported on machine architecture: ${MACHINE}"  
        return 1
    fi    

    local found=$(docker images -q "oracle/database:23.2.0-free")
    if [[ -z "${found}" ]]; then 

        pushd oracle || exit 
        if [ ! -d oracle-docker-images ]; then
            git clone https://github.com/oracle/docker-images oracle-docker-images
        fi

        cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
        ./buildContainerImage.sh -f -v 23.2.0  
        popd    
    fi
}


install_ora() {
    local oraversion=$1

    if [ "${oraversion}" = "oracle/oraxe" ]; then
        install_oraxe
    elif [ "${oraversion}" = "oracle/orafree" ]; then
        install_orafree
    else
        echo "$oraversion"
    fi
}

# return single line of docker ps
# mysql paused 1 /abc/def/xyz
run_docker_compose_ls() {
    local d=${1}
    local filter
    if [ -n "${d}" ]; then filter="--filter name=$d"; fi
    docker compose ls -a $filter \
        | tail -n +2 \
        | awk -F'[[:space:]]+' '{print $1 "," $2 "," $3}' \
        | awk -F'[(),]' '{printf "%s%s,%s,%s,%s",NEWLINE,$1,$2,$3,$5;NEWLINE="\n"}'
}

# have up handle paused vs stopped
run_docker_compose() {
    local cmd=${1:-start}
    local d=${2}
    
    # 0=name
    # 1=status
    readarray -d',' -t DOCKER_LS < <(run_docker_compose_ls "$d")
    case ${cmd} in 
        up) if [[ "${DOCKER_LS[1]}" = "paused" ]]; then docker compose unpause; 
            elif [[ "${DOCKER_LS[1]}" = "exited" ]]; then docker compose start;
            else docker compose up -d; fi
            ;;
        *) docker compose "$cmd"
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

    [ -z "$cmd" ] && echo "docker_compose_others: \$1: not defined" && return 1 
    [ -z "$d" ] && echo "docker_compose_others: \$2: not defined" && return 1 

    if [ ! -d ../$d ] || [ ! -f ../$d/docker-compose.yaml ];then return 1; fi

    pushd $d >/dev/null || return 1
    run_docker_compose "$cmd" "$d"
    if [ -n "$WAIT_TO_COMPLETE" ]; then 
        $WAIT_TO_COMPLETE
    fi
    popd >/dev/null   
}

docker_compose_ora() {
    local cmd=${1}
    local d=${d:-${2}}
    local WAIT_TO_COMPLETE=${3}

    install_ora "$d"

    pushd $d >/dev/null || return 1
    run_docker_compose "$cmd" "$d"
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

    pushd $d >/dev/null || return 1
    case ${cmd} in up|unpause|restart|start) docker compose down -v;; esac   
    run_docker_compose "$cmd" "$d"
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

    echo $cmd $d

    if [ -z "${cmd}" ] || [ -z "${d}" ]; then 
        echo "specify \$1=cmd (up|down|start|stop|restart) and \$2=database" >&2 && return 1
    fi

    pushd $DOCKERDEV_DIR >/dev/null || return 1
    case ${d} in 
        arcion-demo|arcion-demo-test) docker_compose_others "$1" "$2" "wait_arcion_demo";;
        kafka|redis|yugabyte) docker_compose_yb "$1" "$2";;
        oracle/orafree|oracle/oraxe|oracle/oraee) docker_compose_ora "$1" "$2";;
        *) docker_compose_others "$1" "$2";;
    esac
    popd >/dev/null
}

start_db() {
    local db=$1
    local -n start_db_active_db=${2:-ACTIVE_DB}

    [ -z "${db}" ] && echo "\$1=db not specified" && return 1

    echo "$db starting" 
    (( start_db_active_db[$db]+=1))
    docker_compose_db up "$db"
    echo "$db started <<<" 
}

stop_db() {
    local db=$1
    local -n stop_db_active_db=${2:-ACTIVE_DB}

    [ -z "${db}" ] && echo "\$1=db not specified" && return 1

    ((stop_db_active_db[$db]-=1))
    if (( ${stop_db_active_db[$db]} <= 0 )); then 
        echo "$db stopping" 
        docker_compose_db stop "$db"
    else
        echo "$db leaving up" 
    fi
    echo "$db stopped <<<" 
}

