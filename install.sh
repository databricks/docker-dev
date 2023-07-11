#!/usr/bin/env bash

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
    local ora_selected

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
            docker compose up -d
            while [ -z "$( docker compose logs v2130-src 2>&1 | grep -m 1 'DONE: Executing user defined scripts' )" ]; do 
                echo waiting 10 sec for data generation on oraxe-v2130-src; sleep 10; 
            done
        popd
    popd    
}

install_mysql() {
    pushd ${BASE_DIR}/mysql
        docker compose up -d
        while [ -z "$( docker compose logs v8033-src 2>&1 | grep -m 1 'mysqld: ready for connections' )" ]; do 
            echo waiting 10 sec for data generation on mysql-v8033-src; sleep 10; 
        done
    popd        
}

install_pg() {
    pushd ${BASE_DIR}/pg
        docker compose up -d
        while [ -z "$( docker compose logs v1503-src 2>&1 | grep -m 1 -e 'Skipping initialization' -e 'PostgreSQL init process complete; ready for start up.' )" ]; do 
            echo waiting 10 sec for data generation on pg-v1503-src; sleep 10; 
        done
    popd        
}

install_kafka() {
    pushd ${BASE_DIR}/kafka
        docker compose up -d
    popd        
}

install_minio() {
    pushd ${BASE_DIR}/minio
        docker compose up -d
    popd        
}


set_machine

# get dir where this script is at
DIR_NAME="${BASH_SOURCE[0]}"
if [ -z "${DIR_NAME}" ]; then
    echo "Running curl intall.sh"
    BASE_DIR=docker-dev
else 
    BASE_DIR=$( dirname "${DIR_NAME}" )
    echo "Manually running intall.sh from ${BASE_DIR}"
fi


if [[ -n "${ARCION_LICENSE}" ]]; then  
    echo "ARCION_LICENSE found."  
elif [[ -f replicant.lic ]]; then
    echo "ARCION_LICENSE environmental varibale not found."
    echo "replicant.lic found"
    export ARCION_LICENSE="$(cat replicant.lic | base64)"
    echo "Add to your .bashrc or .zprofile:"
    echo "export ARCION_LICENSE='$ARCION_LICENSE'"
else
    abort "ARCION_LICENSE environmental variable not found AND replicant.lic not found"
fi

if [[ $(type -P "git") ]]; then 
    echo "git found." 
else     
    abort "git is NOT in PATH"
fi

if [[ $(type -P "docker") ]]; then 
    echo "docker found." 
else     
    abort "docker is NOT in PATH"
fi

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

oravols=(oraxe11g oraxe2130 oraee1930 arcion-bin)
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
    echo "docker-dev found."
else
    echo "git clone https://github.com/arcionlabs/docker-dev"
    git clone https://github.com/arcionlabs/docker-dev >/tmp/install.$$ 2>&1
    if [[ "$?" != 0 ]]; then 
        cat /tmp/install.$$
        abort "git clone https://github.com/arcionlabs/docker-dev failed."
    fi
fi


# show menu
SELECTED=$(choose_data_providers 3>&1 1>&2 2>&3)

for s in ${SELECTED[@]}; do
    echo $s
    s=$(echo ${s} | tr '[:upper:]' '[:lower:]' | sed 's/"//g' ) # remove the quote surrounding the name 
    case ${s} in
        mysql) install_mysql;;
        oracle) install_oraxe;;
        postgres|pg) install_pg;;
        minio) install_minio;;
        kafka) install_kafka;;
    esac
done

# pull 
docker compose -f ${BASE_DIR}/arcion-demo/docker-compose.yaml pull

# ask to continue
choose_start_cli

# configs are relative to the script
docker compose -f ${BASE_DIR}/arcion-demo/docker-compose.yaml up -d

# start Arcion demo kit CLI
ttyd_started=$( docker compose -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads | grep ttyd )
while [ -z "${ttyd_started}" ]; do
    sleep 1
    echo "waiting on docker compose -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads | grep ttyd"
    ttyd_started=$( docker compose -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads 2>/dev/null | grep ttyd )
done
docker compose -f ${BASE_DIR}/arcion-demo/docker-compose.yaml exec workloads bash -c 'tmux send-keys -t arcion:0.0 "banner arcdemo;sleep 5; arcdemo.sh full mysql postgresql" enter; tmux attach'

