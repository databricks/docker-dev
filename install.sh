#!/usr/bin/env bash

# ARCION_WORKLOADS_TAG: docker tag of robertslee/arcdemo
# ARCION_UI_TAG: docker tag of arcionlabs/replicant-on-premises
# ARCION_DOCKER_DBS: space separated list of dbs to setup (mysql )
# ARCION_DOCKER_COMPOSE: docker compose | docker-compose

# osx=arm
# linux=x86_64
set_machine() {
    export MACHINE=$(uname -p)    
}

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

choose_start_setup() {
    about_textbox='
    The following Arcion demo environment can be setup for you.
    
    +-----------+    +-----------+    +----------+    +-------------+
    |    Load   |    |  Source   |    |  Arcion  |    | Destination |  
    | Generator |    |           |    |          |    |             |
    |           | -->|   MySQL   | -->|  UI/CLI  | -->|    MySQL    |
    |   TPCC    |    | Oracle XE |    |          |    |  Oracle XE  |
    |   YCSB    |    | Postgres  |    | Metadata |    |  Postgres   |
    |           |    |           |    | Grafana  |    |   Minio     |
    |           |    |           |    |          |    |   Kafka     |
    +-----------+    +-----------+    +----------+    +-------------+  

    The source databases will have 1 and 10 million sparse YCSB data.  
    The setup of the containers will be take about 15 minutes.  

    To access the demo using:

    1) UI, open browser to http://localhost:8080
    2) CLI, using tmux terminal.

    Would you like to start the setup?
    '

    if [[ $(which whiptail) ]]; then 
        whiptail --title "Arcion Demo Kit" \
            --yesno "${about_textbox}" 0 0 0
        if (( $? != 0 )); then 
            abort "Exiting the setup."
        fi
    else
        echo "${about_textbox}"
        read -p "Would you like to try the starter demo now (y/n)? " answer
        case ${answer:0:1} in
            n|N )
            abort "Exiting the setup."
            ;;
            * )
            ;;
        esac
    fi
}

choose_start_cli() {
    about_textbox='
    Containers are setup.

    To access the demo using:

    1) UI, open browser to http://localhost:8080 username "admin" password "arcion"
    2) CLI, using tmux terminal. 

    Enter tmux terminal
        docker exec -it arcion-demo-workloads-1 tmux attach

    To start replication:
        arcdemo.sh full mysql pg
        arcdemo.sh full pg kafka
        arcdemo.sh full oraxe minio

    To exit the tmux session:
        1. press <control> b
        2. type ":detach" at the bottom status bar wihout the quote

    Whould you like to be placed into the CLI?
    '
    
    if [[ $(which whiptail) ]]; then 
        whiptail --title "Arcion Demo Kit" \
            --yesno "${about_textbox}" 0 0 0
        if (( $? != 0 )); then 
            abort "Exiting the setup."
        fi
    else
        echo "${about_textbox}"
        read -p "Would you like to enter the CLI demo now (y/n)? " answer
        case ${answer:0:1} in
            n|N )
            abort "Exiting the setup."
            ;;
            * )
            ;;
        esac
    fi
}

choose_data_providers() {
    local ora_whiptail_prompt="OFF"
    local ora_selected   # oracle is not selected by default
        
    if [[ $(which whiptail) ]]; then 
        whiptail --title "Choose Source and Destination Providers" \
        --checklist \
        "Select / Unslect data providers" 0 0 0 \
        MySQL "MySQL V8 source and destination" ON \
        Postgres "Postgres V15 source and destination" ON \
        Kafka "Opensource Kafka destination" ON \
        Minio "S3 destination" ON \
        Oracle "Oracle XE 21c source and destination" ${ora_whiptail_prompt}
    else
        echo "MySQL ${ora_selected} Postgres Kafka Minio" >&3
    fi
}

install_oraxe() {
    if [[ "${MACHINE}" != "x86_64" ]]; then 
        echo "INFO: Oracle not supported on machine architecture: ${MACHINE}"  
        return 1
    fi    

    pushd ${BASE_DIR}/oracle
        if [ ! -d oracle-docker-images ]; then
            git clone https://github.com/oracle/docker-images oracle-docker-images
        fi

        local found=$(docker images -q "oracle/database:21.3.0-xe")
        if [[ -z "${found}" ]]; then 
            pushd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
                ./buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'
            popd
        fi

        pushd oraxe
            $ARCION_DOCKER_COMPOSE up -d
            while [ -z "$( $ARCION_DOCKER_COMPOSE logs v2130-src 2>&1 | grep -m 1 'DONE: Executing user defined scripts' )" ]; do 
                echo waiting 10 sec for data generation on oraxe-v2130-src; sleep 10; 
            done
        popd
    popd    
}

install_mysql() {
    pushd ${BASE_DIR}/mysql
        $ARCION_DOCKER_COMPOSE up -d
        while [ -z "$( $ARCION_DOCKER_COMPOSE logs v8033-src 2>&1 | grep -m 1 'mysqld: ready for connections' )" ]; do 
            echo waiting 10 sec for data generation on mysql-v8033-src; sleep 10; 
        done
    popd        
}

install_pg() {
    pushd ${BASE_DIR}/pg
        $ARCION_DOCKER_COMPOSE up -d
        while [ -z "$( $ARCION_DOCKER_COMPOSE logs v1503-src 2>&1 | grep -m 1 -e 'Skipping initialization' -e 'PostgreSQL init process complete; ready for start up.' )" ]; do 
            echo waiting 10 sec for data generation on pg-v1503-src; sleep 10; 
        done
    popd        
}

install_kafka() {
    pushd ${BASE_DIR}/kafka
        $ARCION_DOCKER_COMPOSE up -d
    popd        
}

install_minio() {
    pushd ${BASE_DIR}/minio
        $ARCION_DOCKER_COMPOSE up -d
    popd        
}


set_machine

# curl or running from docker-dev dir
DIR_NAME="${BASH_SOURCE[0]}"
if [ -z "${DIR_NAME}" ]; then
    echo "Running curl intall.sh"
    BASE_DIR=docker-dev
else 
    BASE_DIR=$( dirname "${DIR_NAME}" )
    echo "Manually running intall.sh from ${BASE_DIR}"
fi

# not inside docker-dev dir
if [[ "$(basename $(pwd))" = "${BASE_DIR}" ]]; then
    abort  "You are inside $BASE_DIR. Please be outside the $BASE_DIR by running 'cd ..'"
else
    echo "Current dir is $(basename $(pwd))"
fi  

# arcion license exists
if [[ -n "${ARCION_LICENSE}" ]]; then  
    echo "ARCION_LICENSE found."  
elif [[ -f replicant.lic ]]; then
    echo "ARCION_LICENSE environmental variable not found."
    echo "replicant.lic found"
    export ARCION_LICENSE="$(cat replicant.lic | base64 -w 0)"
    echo "Add to your .bashrc or .zprofile:"
    echo "export ARCION_LICENSE='$ARCION_LICENSE'"
else
    abort "ARCION_LICENSE environmental variable not found AND replicant.lic not found"
fi

# git exists
if [[ $(type -P "git") ]]; then 
    echo "git found." 
else     
    abort "git is NOT in PATH"
fi

# docker exists
if [[ $(type -P "docker") ]]; then 
    echo "docker found." 
else     
    abort "docker is NOT in PATH"
fi

# docker is up and running
docker ps --all >/dev/null || abort "docker is not running.  Please start docker"

# docker version >= 19.3.0
readarray -d ' ' ARCION_DOCKER_VERSION < <(docker version --format '{{.Client.Version}}' | awk -F'.' '{printf "%s %s %s",$1,$2,$3}')
if (( ${ARCION_DOCKER_VERSION[0]} <= 19 )) && (( ${ARCION_DOCKER_VERSION[1]} < 3 )); then
    abort "docker 19.3.0 or greater needed. $(echo  ${ARCION_DOCKER_VERSION[*]} | tr '[:space:]' '.') found."
fi

# docker compose or docker-compose
docker compose --help >/dev/null 2>/dev/null
if [[ "$?" == "0" ]]; then
    ARCION_DOCKER_COMPOSE="docker compose"
else
    docker-compose --help >/dev/null 2>/dev/null
    if [[ "$?" == "0" ]]; then
        ARCION_DOCKER_COMPOSE="docker-compose"
    else
        abort "docker compose and docker-compose not found."
    fi
fi
echo "Found ${ARCION_DOCKER_COMPOSE}."

# startup screen
choose_start_setup

docker network inspect arcnet >/dev/null 2>/dev/null
if [[ "$?" == "0" ]]; then
    echo "docker network arcnet found."
else 
    echo "docker network create arcnet"
    docker network create arcnet >/tmp/install.$$ 2>&1
    if [[ "$?" != 0 ]]; then 
        cat /tmp/install.$$
        abort "docker network create arcnet failed."
    fi
fi

oravols=(oraee_v1930-src oraxe_v2130-src ora-shared-rw arcion-bin)
for v in ${oravols[*]}; do
    docker volume inspect $v >/dev/null 2>/dev/null
    if [[ "$?" = "0" ]]; then
        echo "docker volume $v found."
    else
        echo "docker volume create $v"
        docker volume create $v >/tmp/install.$$ 2>&1
        if [[ "$?" != 0 ]]; then 
            cat /tmp/install.$$
            abort "docker create $v failed."
        fi
    fi    
done

if [[ -d "docker-dev" ]]; then
    echo "docker-dev found. running git pull"
    pushd docker-dev
    if [ -z "${ARCION_WORKLOADS_TAG}" ]; then
        git pull
    else
        git config pull.rebase false
        git pull origin ${ARCION_WORKLOADS_TAG}
        git checkout ${ARCION_WORKLOADS_TAG}
    fi
    popd
else
    echo "git clone https://github.com/arcionlabs/docker-dev"
    git clone https://github.com/arcionlabs/docker-dev >/tmp/install.$$ 2>&1
    if [[ "$?" != 0 ]]; then 
        cat /tmp/install.$$
        abort "git clone https://github.com/arcionlabs/docker-dev failed."
    fi
fi

# show menu
if [ -z "${ARCION_DOCKER_DBS}" ]; then
    ARCION_DOCKER_DBS=$(choose_data_providers 3>&1 1>&2 2>&3)
fi

for s in ${ARCION_DOCKER_DBS[@]}; do
    echo $s
    s=$(echo ${s} | tr '[:upper:]' '[:lower:]' | sed 's/"//g' ) # remove the quote surrounding the name 
    case ${s} in
        mysql) install_mysql;;
        oracle) install_oraxe;;
        postgres|pg) install_pg;;
        minio) install_minio;;
        kafka) install_kafka;;
        *)
            pushd ${s}
            $ARCION_DOCKER_COMPOSE up -d 
            popd
            ;;
    esac
done

# pull 
$ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml pull || abort "please see the error msg"

# ask to continue
choose_start_cli

# configs are relative to the script
$ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml up -d || abort "please see the error msg"

# start Arcion demo kit CLI
ttyd_started=$( $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads | grep ttyd )
while [ -z "${ttyd_started}" ]; do
    sleep 1
    echo "waiting on $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads | grep ttyd"
    ttyd_started=$( $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads 2>/dev/null | grep ttyd )
done
$ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml exec workloads bash -c 'tmux send-keys -t arcion:0.0 "figlet -t arcdemo;sleep 5; arcdemo.sh full mysql postgresql" enter; tmux attach'

