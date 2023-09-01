#!/usr/bin/env bash

# ARCION_WORKLOADS_TAG: docker tag of robertslee/arcdemo
# ARCION_UI_TAG: docker tag of arcionlabs/replicant-on-premises
# ARCION_DOCKER_DBS: space separated list of dbs to setup (mysql )
# ARCION_DOCKER_COMPOSE: docker compose | docker-compose

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}
# MACHINE
setMachineType() {
    # osx=arm
    # linux=x86_64
    export MACHINE=$(uname -p)    
}
# BASE_DIR
setBasedir() {
    # curl or running from docker-dev dir
    DIR_NAME="${BASH_SOURCE[0]}"
    if [ -z "${DIR_NAME}" ]; then
        echo "Running curl intall.sh"
        export BASE_DIR=docker-dev

        # not inside docker-dev dir
        if [[ "$(basename $(pwd))" = "${BASE_DIR}" ]]; then
            abort  "You are inside $BASE_DIR. Please be outside the $BASE_DIR by running 'cd ..'"
        else
            echo "Current dir is $(basename $(pwd))"
        fi  
    else 
        export BASE_DIR=$( dirname "${DIR_NAME}" )
        echo "Manually running intall.sh from ${BASE_DIR}"
    fi
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
# ARCION_DOCKER_DBS
chooseDataProviders() {
    if [ -n "${ARCION_DOCKER_DBS}" ]; then
        return
    fi

    declare -A "data_provider_dict=($(find * -maxdepth 2 \
        -not \( -path docker-dev -prune \) \
        -name "docker-compose.yaml" -printf "%h\n" | awk '{printf "[%s]=%s ",$1,$1}')
    )" 

    dialog_output=/tmp/whiptail.out
    whiptail --title "Select database to start" \
    --output-fd 4 \
    --checklist \
    "List of databases" 0 0 0 \
    $( for d in  printf '%s\n' "${!data_provider_dict[@]}" | sort; do echo $d $d OFF; done ) \
    4> ${dialog_output}

    export ARCION_DOCKER_DBS=$(cat $dialog_output)

}
chooseDataProviders_old() {
    # show menu
    if [ -n "${ARCION_DOCKER_DBS}" ]; then
        return
    fi
    
    local ora_whiptail_prompt

    if [[ "${MACHINE}" = "x86_64" ]]; then 
        ora_whiptail_prompt="ON"
    else
        ora_whiptail_prompt="OFF"
    fi

    dialog_output=/tmp/whiptail.out
    if [[ $(which whiptail) ]]; then 
        runWhiptail "${dialog_output}"        
        export ARCION_DOCKER_DBS=$(cat $dialog_output)
    else
        if [[ "${MACHINE}" = "x86_64" ]]; then 
            ora_selected=${ora_selected:-Oracle}
        fi
        export ARCION_DOCKER_DBS=$(
            echo "MySQL ${ora_selected} Postgres Kafka Minio"
        )
    fi
}

downloadFromGdrive() {
    local FILEID=$1
    local FILENAME=$2

    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=FILEID' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=${FILEID}" -O ${FILENAME} && rm -rf /tmp/cookies.txt
}

install_oraee() {
    local found=$(docker images -q "oracle/database:19.3.0-ee")
    if [[ -n "${found}" ]]; then
        return 0
    fi 

    pushd $BASE_DIR/oracle || exit 

    if [ ! -d oracle-docker-images ]; then
        git clone https://github.com/oracle/docker-images oracle-docker-images \
            || abort "Error: git clone https://github.com/oracle/docker-images oracle-docker-images"
    fi
    cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 

    if [[ "${MACHINE}" = "x86_64" ]]; then 
        image=LINUX.X64_193000_db_home.zip
        arcion_image=$ARCION_ORA193AMD
    else  
        image=LINUX.ARM64_1919000_db_home.zip
        arcion_image=$ARCION_ORA193ARM
    fi

    # prepare image
    if [ ! -f "19.3.0/$image" ] && [ -f ~/Downloads/$image ]; then
        echo cp ~/Downloads/$image 19.3.0/.
        cp ~/Downloads/$image 19.3.0/.
    elif [ -n "${arcion_image}" ]; then
        downloadFromGdrive "${arcion_image}" 19.3.0/${image}
    fi

    # bail if not manually downloaded and does not have internal usage
    if [ ! -f "19.3.0/$image" ]; then
        abort "Error: $(pwd)/19.3.0/$image not found"
    fi

    ./buildContainerImage.sh -v 19.3.0 -e -o '--build-arg SLIMMING=false'
    popd    
}

install_oraxe() {
    if [[ "${MACHINE}" != "x86_64" ]]; then 
        echo "INFO: Oracle not supported on machine architecture: ${MACHINE}"  
        return 1
    fi    

    local found=$(docker images -q "oracle/database:21.3.0-xe")
    if [[ -n "${found}" ]]; then
        return 0
    fi 

    pushd $BASE_DIR/oracle || exit 

    if [ ! -d oracle-docker-images ]; then
        git clone https://github.com/oracle/docker-images oracle-docker-images \
            || abort "Error: git clone https://github.com/oracle/docker-images oracle-docker-images"
    fi
    cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 

    ./buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'
    popd    

}

install_orafree() {
    if [[ "${MACHINE}" != "x86_64" ]]; then 
        echo "INFO: Oracle not supported on machine architecture: ${MACHINE}"  
        return 1
    fi    

    local found=$(docker images -q "oracle/database:23.2.0-free")
    if [[ -n "${found}" ]]; then
        return 0
    fi 

    pushd $BASE_DIR/oracle || exit 

    if [ ! -d oracle-docker-images ]; then
        git clone https://github.com/oracle/docker-images oracle-docker-images \
            || abort "Error: git clone https://github.com/oracle/docker-images oracle-docker-images"
    fi
    cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 

    ./buildContainerImage.sh -v 23.2.0 -f -o '--build-arg SLIMMING=false'
    popd    

}


install_ora() {
    local oraversion=$1

    if [ "${oraversion}" = "oracle/oraxe" ]; then
        install_oraxe
    elif [ "${oraversion}" = "oracle/orafree" ]; then
        install_orafree
    elif [ "${oraversion}" = "oracle/oraee" ]; then
        install_oraee
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
    $ARCION_DOCKER_COMPOSE ls -a $filter \
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
        up) if [[ "${DOCKER_LS[1]}" = "paused" ]]; then $ARCION_DOCKER_COMPOSE unpause; 
            elif [[ "${DOCKER_LS[1]}" = "exited" ]]; then $ARCION_DOCKER_COMPOSE start;
            else 
                export DOCKER_BUILDKIT=0
                $ARCION_DOCKER_COMPOSE build
                $ARCION_DOCKER_COMPOSE up -d 
            fi
            ;;
        *) $ARCION_DOCKER_COMPOSE "$cmd"
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

    if [ ! -d $d ] || [ ! -f $d/docker-compose.yaml ];then 
        echo "$d not a dir || ! -f $d/docker-compose.yaml" >&2
        return 1 
    fi

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
    case ${cmd} in up|unpause|restart|start) $ARCION_DOCKER_COMPOSE down -v;; esac   
    run_docker_compose "$cmd" "$d"
    if [ -n "$WAIT_TO_COMPLETE" ]; then 
        $WAIT_TO_COMPLETE
    fi
    popd >/dev/null
}

wait_arcion_demo() {
    ttyd_started=$( $ARCION_DOCKER_COMPOSE logs workloads | grep ttyd )
    while [ -z "${ttyd_started}" ]; do
        sleep 1
        echo "waiting on $ARCION_DOCKER_COMPOSE logs workloads | grep ttyd"
        ttyd_started=$( $ARCION_DOCKER_COMPOSE logs workloads | grep ttyd )
    done
}

# run docker compose cmd database
docker_compose_db() {
    local cmd=${1}
    local d=${2}

    echo $cmd $d

    checkDockerCompose

    if [ -z "${cmd}" ] || [ -z "${d}" ]; then 
        echo "specify \$1=cmd (up|down|start|stop|restart) and \$2=database" >&2 && return 1
    fi

    pushd $BASE_DIR >/dev/null || return 1
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


checkArcionLicese() {
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
}
checkGit() {
    # git exists
    if [[ $(type -P "git") ]]; then 
        echo "git found." 
    else     
        abort "git is NOT in PATH"
    fi
}
# ARCION_DOCKER_COMPOSE
checkDockerCompose() {
    if [ -n "${ARCION_DOCKER_COMPOSE}" ]; then
        return 0
    fi

    # docker compose or docker-compose
    docker compose --help >/dev/null 2>/dev/null
    if [[ "$?" == "0" ]]; then
        export ARCION_DOCKER_COMPOSE="docker compose"
    else
        docker-compose --help >/dev/null 2>/dev/null
        if [[ "$?" == "0" ]]; then
            export ARCION_DOCKER_COMPOSE="docker-compose"
        else
            abort "docker compose and docker-compose not found."
        fi
    fi
    echo "Found ${ARCION_DOCKER_COMPOSE}."
}
checkDocker() {
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
}
createArcnet() {
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
}
createVolumes() {
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
}
pullDockerDev() {
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
}
pullArcdemo() {
    # pull 
    $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml pull || abort "please see the error msg"
}

startDatabases() {
    echo ${ARCION_DOCKER_DBS[@]}
    for db in ${ARCION_DOCKER_DBS[@]}; do
        db=$(echo ${db} | sed 's/"//g' ) # remove the quote surrounding the name
        docker_compose_db up $db
    done
}
startArcdemo() {
    # configs are relative to the script
    $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml up -d || abort "please see the error msg"

    # start Arcion demo kit CLI
    ttyd_started=$( $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads | grep ttyd )
    while [ -z "${ttyd_started}" ]; do
        sleep 1
        echo "waiting on $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads | grep ttyd"
        ttyd_started=$( $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml logs workloads 2>/dev/null | grep ttyd )
    done
    $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml exec workloads bash -c 'tmux send-keys -t arcion:0.0 "clear" enter'
    sleep 1
    $ARCION_DOCKER_COMPOSE -f ${BASE_DIR}/arcion-demo/docker-compose.yaml exec workloads bash -c 'tmux send-keys -t arcion:0.0 "arcdemo.sh full mysql postgresql"; tmux attach'
}

(return 0 2>/dev/null) && sourced=1 || sourced=0
if (( sourced == 0 )); then
    # choose prereq check
    choose_start_setup

    setMachineType
    setBasedir
    checkArcionLicense
    checkGit
    checkDocker
    checkDockerCompose

    createArcnet
    createVolumes
    pullDockerDev
    pullArcdemo

    # choose databases
    chooseDataProviders
    startDatabases

    # choose demo run
    choose_start_cli
    startArcdemo
fi
