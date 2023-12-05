#!/usr/bin/env bash

abort() {
    printf "%s\n" "$@" >&2
    if (( ARCION_INSTALL_SOURCED == 1 )); then   
        return 1
    else
        exit 1
    fi
}

if [ -z "$BASH_VERSINFO" ]; then
    abort "BASH_VERSION not defined"
fi

if (( ${BASH_VERSINFO[0]} < 4 )); then
    abort "bash 4.0 or greater needed. $BASH_VERSION found."
fi

# ARCION_WORKLOADS_TAG: docker tag of robertslee/arcdemo
# ARCION_UI_TAG: docker tag of arcionlabs/replicant-on-premises
# ARCION_DOCKER_DBS: space separated list of dbs to setup (mysql )
# ARCION_DOCKER_COMPOSE: podman-compose | docker compose | docker-compose
# ARCION_DOCKER: podman | docker

# workaround to export the dict
# where this is required, do the following
#   eval ${default_oraver_table_dict_export}
#   declare -p default_oraver_table_dict_export 

# oracle docker image name from `docker image`
declare -A default_oraver_image_dict=(
    ["oraee-v1930-x86_64"]="oracle/database:19.3.0-ee" 
    ["oraee-v1930-arm"]="oracle/database:19.3.0-ee" 
    ["oraxe-v2130-x86_64"]="" 
    ["oraee-v2130-x86_64"]="oracle/database:21.3.0-ee" 
    ["orafree-v2320-x86_64"]="oracle/database:23.2.0-free"
    )

# oracle zip file
declare -A default_oraver_zip_dict=(
    ["oraee-v1930-x86_64"]="LINUX.X64_193000_db_home.zip" 
    ["oraee-v1930-arm"]="LINUX.ARM64_191900_db_home.zip"
    ["oraee-v2130-x86_64"]="LINUX.X64_213000_db_home.zip" 
    ["oraxe-v2130-x86_64"]="" 
    ["orafree-v2320-x86_64"]=""
    )

# env variable that has gdrive link to download the binary for internal use
declare -A default_oraver_gdrive_dict=(
    ["oraee-v1930-x86_64"]="ARCION_ORA193000_AMD" 
    ["oraee-v1930-arm"]="ARCION_ORA193000_ARM"
    ["oraee-v2130-x86_64"]="ARCION_ORA213000_AMD" 
    ["oraxe-v2130-x86_64"]="" 
    ["orafree-v2320-x86_64"]=""
    )

# command to build the docker image
# command to build the docker image
declare -A default_oraver_builddir_dict=(
    ["oraee-v1930-x86_64"]="19.3.0" 
    ["oraee-v1930-arm"]="19.3.0" 
    ["oraee-v2130-x86_64"]="21.3.0" 
    ["oraxe-v2130-x86_64"]="21.3.0" 
    ["orafree-v2320-x86_64"]="23.2.0"
    )

declare -A default_oraver_buildcmd_dict=(
    ["oraee-v1930-x86_64"]="buildContainerImage.sh -v 19.3.0 -e -o '--build-arg SLIMMING=false'" 
    ["oraee-v1930-arm"]="buildContainerImage.sh -v 19.3.0 -e -o '--build-arg SLIMMING=false'" 
    ["oraee-v2130-x86_64"]="buildContainerImage.sh -v 21.3.0 -e -o '--build-arg SLIMMING=false'" 
    ["oraxe-v2130-x86_64"]="buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'" 
    ["orafree-v2320-x86_64"]="buildContainerImage.sh -v 23.2.0 -f -o '--build-arg SLIMMING=false'"
    )

    

# DOCKERDEV_NAME
setDockerDevName() {
    [ -z "${DOCKERDEV_NAME}" ] && export DOCKERDEV_NAME="docker-dev"
}

# MACHINE
setMachineType() {
    # osx=arm64
    # linux=x86_64
    [ -z "${MACHINE}" ] && export MACHINE="$(uname -m)"    
    case ${MACHINE} in
        arm64|x86_64) echo "$MACHINE detected.";; 
        *) abort "MACHINE $MACHINE not handled.";;
    esac
}
# DOCKERDEV_BASEDIR
# DOCKERDEV_INSTALL=1|""
setBasedir() {
    # curl or running from docker-dev dir
    DIR_NAME="${BASH_SOURCE[0]}"
    if [ -z "${DIR_NAME}" ]; then
        echo "Running curl intall.sh" >&2
        export DOCKERDEV_INSTALL=1
        # inside docker-dev dir
        if [[ "$(basename $(pwd))" = "${DOCKERDEV_NAME}" ]]; then
            abort  "You are inside $DOCKERDEV_BASEDIR. Please be outside the $DOCKERDEV_BASEDIR by running 'cd ..' or run ./install.sh"
        fi
        echo "mkdir ${DOCKERDEV_NAME}" >&2
        mkdir ${DOCKERDEV_NAME}
        export DOCKERDEV_BASEDIR="$(pwd)/${DOCKERDEV_NAME}"
        echo "Internet install of intall.sh from ${DOCKERDEV_BASEDIR}" >&2
    else 
        export DOCKERDEV_INSTALL=""
        export DOCKERDEV_BASEDIR="$(readlink -f $(dirname ${DIR_NAME}))"
        echo "Manually running intall.sh from ${DOCKERDEV_BASEDIR}" >&2
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

    if [[ -n "${CLIMENU}" ]]; then 
        $CLIMENU --title "Arcion Demo Kit" \
            --yesno "${about_textbox}" 0 0
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
        docker exec -it arcdemo-workloads-1 tmux attach

    To start replication:
        arcdemo.sh full mysql pg
        arcdemo.sh full pg kafka
        arcdemo.sh full oraxe minio

    To exit the tmux session:
        1. press <control> b
        2. type ":detach" at the bottom status bar wihout the quote

    Whould you like to be placed into the CLI?
    '
    
    if [[ -n "${CLIMENU}" ]]; then 
        ${CLIMENU} --title "Arcion Demo Kit" \
            --yesno "${about_textbox}" 0 0
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

getDockerComposeFiles() {
        find ${DOCKERDEV_BASEDIR} -maxdepth 3 \
        -not \( -path "${DOCKERDEV_BASEDIR}/${DOCKERDEV_NAME}" -prune \) \
        -name "*compose*.yaml" | sed "s|^${DOCKERDEV_BASEDIR}/||" | getNameVerFromYaml
}

# ARCION_DOCKER_DBS="mysql,ON mysql,OFF"
chooseDataProviders() {

    composefile_output=/tmp/composefile.$$.txt      # Name-ver
    composels_output=/tmp/composels.$$.txt          # Name-ver,Status(es),RunningCount,NotRunningCount,ConfigFile    
    whiptail_input=/tmp/whiptail_input.$$.txt       # Name-ver,Status(es),ON|OFF
    whiptail_unsorted=/tmp/whiptailselection.$$.txt # Name-ver,ON|OFF
    whiptail_output=/tmp/whiptailselectionsorted.$$.txt   # Name-ver,ON|OFF

    # all docker compose dirs. for oracle/oraxe show oraxe
    getDockerComposeFiles | sort -t, -u > ${composefile_output}

    # all running and stopped docker compose 
    # Name-ver,Status(es),RunningCount,NotRunningCount,ConfigFile
    run_docker_compose_ls | sort -t, -u >   ${composels_output}   

    # join key field -1 1 -2 2 
    # left join (-a 1)
    # fields 1.1 file 1.field 1 (-o)
    # name status(1/2)_dir 
    join -t, -a 1 -o "1.2 2.3 2.4 2.5 2.6"  ${composefile_output} ${composels_output} | \
        awk -F',' '{
            # $4==0 make sure nothing is in exited / paused / stopped status
            if (index($2,"running") && $4==0) {onoff="ON"} 
            else {onoff="OFF"}; 
            if ($3=="" && $4=="") printf "%s,,%s\n",$1,onoff;
            else printf "%s,running(%s)/not(%s),%s\n",$1,$3,$4,onoff;}' | \
        sort -t, > ${whiptail_input}   
    readarray -d ',' -t whiptailmenu < <(cat ${whiptail_input} | tr '\n' ',')

    $CLIMENU --title "Select / Deselet To Start/Stop Service" --output-fd 4 --separate-output \
    --checklist "Later, re-run docker-dev/install.sh or manually: 
    cd mysql; docker compose up -d
    cd mysql; docker compose stop" \
    0 0 0 \
    "${whiptailmenu[@]}" \
    4> ${whiptail_unsorted}

    if [[ "$?" != "0" ]]; then return; fi

    sort -t, ${whiptail_unsorted} > ${whiptail_output}

    # mysql,ON|OFF oraxe,ON|OFF 
    export ARCION_DOCKER_DBS=$(
            join -t, -a 1 -e OFF -o "1.1 1.2 1.3 2.1" <(sort -t, ${whiptail_input}) <(sort -t, ${whiptail_output}) | \
                awk -F',' '
                # previous and new state
                # on on = on (no change)
                # off off = off (no change)
                $1 == $NF && $(NF-1)=="ON" {next} 
                # previous and new state not same and and new state
                # the new state not off, then it is on 
                # off on = on
                # on off = off
                $(NF-1) != $NF {if ($NF!="OFF") $NF="ON"; printf "%s,%s\n",$1,$NF}'
        )
}

downloadFromGdrive() {
    local FILEID=$1
    local FILENAME=$2

    wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=FILEID' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=${FILEID}" -O ${FILENAME} && rm -rf /tmp/cookies.txt
}

# assume we are in $DOCKERDEV_BASEDIR
# build_ora "$docker_project" "${compose_file}"
build_ora() {
    local docker_project="$1"
    local compose_file="$2"

    echo $docker_project
    echo $compose_file
    echo $MACHINE
    
    local key="${docker_project}-${MACHINE}"
    echo $key

    # see if image already exists
    local image_name=${default_oraver_image_dict[${key}]}
    if [ -z "$image_name" ]; then 
        echo "${key} not in default_oraver_image_dict table" >&2
        popd > /dev/null || return 1
        return 0    
    fi

    echo "checking docker image ls -q ${image_name}"
    local found=$($ARCION_DOCKER image ls -q "${image_name}")
    echo $found
    if [[ -n "${found}" ]]; then
        echo "found docker image ls -q ${image_name}" >&2
        #DEBUG 
        return 0
    fi 

    # git clone the oracle docker image builder
    pushd $DOCKERDEV_BASEDIR/oracle || return 1
    if [ ! -d oracle-docker-images ]; then
        git clone https://github.com/oracle/docker-images oracle-docker-images \
            || abort "Error: git clone https://github.com/oracle/docker-images oracle-docker-images"
    else
        git fetch || return 1
    fi

    # prepare the oracle zip file
    local zip_name=${default_oraver_zip_dict[${key}]}
    local gdrive_name=${default_oraver_gdrive_dict[${key}]}
    local builddir_name=${default_oraver_builddir_dict[${key}]}
    local gdrive_link=${!gdrive_name}

    echo "gdrive_name=$gdrive_name"
    echo "builddir_name=$builddir_name"
    echo "gdrive_link=${!gdrive_name}"
    cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles || return 1
    # download the zip file if required
    if [ -n "$zip_name" ]; then
        echo "checking for $zip_name"
        if [ -f "$builddir_name/$zip_name" ]; then
            echo "found $builddir_name/$zip_name"
        else
            echo "$builddir_name/$zip_name does not exist"

            echo "checking for ~/Downloads/$zip_name $builddir_name/."
            if [ -f ~/Downloads/$zip_name ]; then
                echo "found cp ~/Downloads/$zip_name $builddir_name/."
                cp ~/Downloads/$zip_name $builddir_name/.
            elif [ -n "${zip_name}" ] && [ -n "${gdrive_link}" ]; then
                echo "downloadFromGdrive ${gdrive_link} $builddir_name/$zip_name"
                downloadFromGdrive "${gdrive_link}" "$builddir_name/$zip_name"
            else
                abort "Error: $(pwd)/$builddir_name/$zip_name not found"
            fi
        fi
    fi

    # bulild the image - will take a while
    local buildcmd_name=${default_oraver_buildcmd_dict[${key}]}
    if [ -z "$buildcmd_name" ]; then
        abort "default_oraver_buildcmd_dict[$key] not defined"
    fi
    echo $buildcmd_name
    export DOCKER_BUILDKIT=0
    eval "./${buildcmd_name}"
    popd > /dev/null || return 1    
}

# make oraxe/docker-compose-v11.yaml to oraxe-v11
getNameVerFromYamlRemoveSlash() {
    local F=${1:-1}
    awk -F'\t' -v F=${F} '{split($F,c,"/"); n[$1]=c[length(c)-1]; split(c[length(c)],y,"[-|.]"); x=y[length(y)-1]; if (x=="compose") v[$F]=""; else v[$1]=("-" x);} 
        END {for (k in n) {printf "%s%s\n",n[k],v[k]}}'
}

getNameVerFromYaml() {
    local F=${1:-1}
    # dir dirname
    # dcf docker compose yaml file name
    awk -F'/' -v F=${F} '{
        dir=$1; 
        for (i=2;i<NF;i++) {dir=(dir "/" $i)}; 
        split($NF,dcy,"[-|.]"); v=dcy[length(dcy)-1]; 
        if (v=="compose") v=""; else v=("-" v); 
        printf "%s,%s%s\n",$0,dir,v;
        }' 
}


# ConfigFile,Name[-ver],Status(es),RunningCount,NotRunningCount
run_docker_compose_ls() {
    local d=${1}
    local filter

    [ -n "${d}" ] && filter="--filter name=$d"
    
    containerid=($($ARCION_DOCKER ps --all -q ${filter}))

    if [ -z "${containerid}" ]; then return; fi

    $ARCION_DOCKER inspect ${containerid[@]} | \
    jq -r '.[] | [.Config.Labels."com.docker.compose.project.config_files", .State.Status] | @tsv' | \
    awk -F'\t' '{split($1,c,"/"); n[$1]=c[length(c)-1]; split(c[length(c)],y,"[-|.]"); x=y[length(y)-1]; if (x=="compose") v[$1]=""; else v[$1]=("-" x);}
    {r[$1]+=0; nr[$1]+=0; s[$1]=(s[$1] $2 "|"); if ($2=="running") r[$1]++; else nr[$1]++; } 
    END {for (k in s) {if (k!="") printf "%s,%s%s,%s,%s,%s\n",k,n[k],v[k],s[k],r[k],nr[k]}}' | \
    sed "s|^${DOCKERDEV_BASEDIR}/||" 
    # per line vars
    # c= config split by / array
    # y= yaml split by [-|.]
    # global arrays
    # n= name
    # v= version
    # s= statues
    # r= running count
    # nr= not running count
    # i=containerid
    # don't print non docker compose 
}


# have up handle paused vs stopped
run_docker_compose() {
    local cmd=${1:-start}
    local d=${2}
    local compose_file=${3:-"docker-compose.yaml"}

    echo "run_docker_compose $cmd $d $compose_file" $(pwd)
    
    # ConfigFile,Name[-ver],Status(es),RunningCount,NotRunningCount
    readarray -d',' -t DOCKER_LS < <(run_docker_compose_ls "$d" | grep "${compose_file}")
    case ${cmd} in 
        up) if [[ "${DOCKER_LS[2]}" =~ "paused" ]]; then 
                $ARCION_DOCKER_COMPOSE -f ${compose_file} unpause || abort "${pwd} $ARCION_DOCKER_COMPOSE unpause failed" 
            elif [[ "${DOCKER_LS[2]}" =~ "exited" ]]; then 
                $ARCION_DOCKER_COMPOSE -f ${compose_file} start || abort "${pwd} $ARCION_DOCKER_COMPOSE start failed"
            else 
                export DOCKER_BUILDKIT=0
                $ARCION_DOCKER_COMPOSE -f ${compose_file} build
                $ARCION_DOCKER_COMPOSE -f ${compose_file} up -d || abort "${pwd} $ARCION_DOCKER_COMPOSE up -d failed" 
            fi
            ;;
        *) $ARCION_DOCKER_COMPOSE -f ${compose_file} "$cmd" || abort "${pwd} $ARCION_DOCKER_COMPOSE ${cmd} -d failed"
            ;;
    esac
}


# will be inside the bin dir
# $1=start|pause|unpause
# $2=dirname ie mysql|mariadb|..
docker_compose_others() {
    local cmd=${1:-up}
    local d=${d:-${2}}
    local ver=${3}
    local compose_file=${4}
    local WAIT_TO_COMPLETE=${5}

    [ -z "$cmd" ] && echo "docker_compose_others: \$1: not defined" && return 1 
    [ -z "$d" ] && echo "docker_compose_others: \$2: not defined" && return 1 

    if [ ! -d $d ] || [ ! -f ${d}/${compose_file} ];then 
        echo "$(pwd)/$d not a dir || ! -f $d/${compose_file}" >&2
        return 1 
    fi

    pushd $d >/dev/null || return 1
    d=${d##*/}  # ##=greedy trim, *=match anything, /=until the lasts / returning the basename
    run_docker_compose "$cmd" "$d" "${compose_file}"
    if [ -n "$WAIT_TO_COMPLETE" ]; then 
        $WAIT_TO_COMPLETE
    fi
    popd >/dev/null   
}

docker_compose_ora() {
    local cmd=${1:-up}      # up|stop
    local d=${d:-${2}}      # oracle/oraee
    local ver=${3}          # v11
    local compose_file=${4} # docker-compose-v11.yaml
    local WAIT_TO_COMPLETE=${5}

    docker_project=${d##*/}  # ##=greedy trim, *=match anything, /=until the lasts / returning the basename
    build_ora "$docker_project" "${compose_file}"

    pushd $d >/dev/null || return 1
    run_docker_compose "$cmd" "$docker_project" "${compose_file}"
    if [ -n "$WAIT_TO_COMPLETE" ]; then 
        $WAIT_TO_COMPLETE
    fi
    popd >/dev/null
}

# yb does not come back up 
docker_compose_yb() {
    local cmd=${1:-up}
    local d=${d:-${2}}
    local ver=${3}
    local compose_file=${4}
    local WAIT_TO_COMPLETE=${5}

    pushd $d >/dev/null || return 1
    d=${d##*/}  # ##=greedy trim, *=match anything, /=until the lasts / returning the basename

    case ${cmd} in up|unpause|restart|start) $ARCION_DOCKER_COMPOSE -f "${compose_file}" down -v;; esac   
    run_docker_compose "$cmd" "$d" "${compose_file}"
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
    local ver=${3}
    local WAIT_TO_COMPLETE=${4}

    echo $cmd $d $ver>&2

    checkDockerCompose

    if [ -z "${cmd}" ] || [ -z "${d}" ]; then 
        echo "specify \$1=cmd (up|down|start|stop|restart) and \$2=database" >&2 && return 1
    fi

    if [[ -z "$ver" ]]; then compose_file="docker-compose.yaml"; else compose_file="docker-compose-${ver}.yaml"; fi

    pushd $DOCKERDEV_BASEDIR >/dev/null || return 1
    case ${d} in 
        arcdemo*) docker_compose_others "$1" "$2" "$3" "$compose_file" "wait_arcion_demo";;
        kafka|redis|yugabyte) docker_compose_yb "$1" "$2" "$3" "$compose_file";;
        oracle*) docker_compose_ora "$1" "$2" "$3" "$compose_file";;
        *) docker_compose_others "$1" "$2" "$3" "$compose_file";;
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


checkArcionLicense() {
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
        abort "git is NOT in PATH. Please install via
        sudo apt-get install git
        brew install git
        "
    fi
}

checkJq() {
    if [[ $(type -P "jq") ]]; then 
        echo "jq found." 
    else     
        abort "jq is NOT in PATH. Please install via
        sudo apt-get install jq
        brew install jq
        "
    fi
}
# CLIMENU
setWhiptailDialog() {
    # git exists
    [ -n "${CLIMENU}" ] && return 0

    if [[ -n $(which whiptail) ]]; then 
        echo "whiptail founded." 
        export CLIMENU=whiptail
    elif [[ -n $(which dialog) ]]; then 
        echo "dialog founded." 
        export CLIMENU="dialog --no-collapse"
    else     
abort "whiptail or dialog not found.
on OSX 
    brew install newt or brew install dialog
on Linux or Windows WSL
    sudo apt-get install whiptail"
    fi
}
# ARCION_DOCKER_COMPOSE
checkDockerCompose() {
    if [ -n "${ARCION_DOCKER_COMPOSE}" ]; then
        echo "Using ${ARCION_DOCKER_COMPOSE}"
        return 0
    fi

    podman-compose --help >/dev/null 2>/dev/null
    if [[ "$?" == "0" ]]; then
        export ARCION_DOCKER_COMPOSE="podman-compose"
        echo "${ARCION_DOCKER_COMPOSE} found."
        return
    fi

    # docker compose or docker-compose
    docker compose --help >/dev/null 2>/dev/null
    if [[ "$?" == "0" ]]; then
        export ARCION_DOCKER_COMPOSE="docker compose"
        echo "${ARCION_DOCKER_COMPOSE} found."
        return
    fi

    docker-compose --help >/dev/null 2>/dev/null
    if [[ "$?" == "0" ]]; then
        export ARCION_DOCKER_COMPOSE="docker-compose"
        echo "${ARCION_DOCKER_COMPOSE} found."
        return
    fi

    abort "docker compose, docker-compose or podman-compose not found."
}

# ARCION_DOCKER
checkDocker() {
    if [ -n "${ARCION_DOCKER}" ]; then
        echo "Using ${ARCION_DOCKER}"
        return 0
    fi

    # docker exists
    if [[ $(type -P "podman") ]]; then 
        echo "podman found." 
        export ARCION_DOCKER="podman"

        # docker is up and running
        podman ps --all >/dev/null || abort "podman is not running.  Please start podman"

        # podman version >= 4.17.0
        readarray -d ' ' ARCION_PODMAN_VERSION < <(podman version --format '{{.Client.Version}}' | awk -F'.' '{printf "%s %s %s",$1,$2,$3}')
        if (( ${ARCION_PODMAN_VERSION[0]} < 3 )); then
            abort "podman 4.17.0 or greater needed. $(echo  ${ARCION_PODMAN_VERSION[*]} | tr '[:space:]' '.') found."
        fi
        return 0
    fi

    # docker exists
    if [[ $(type -P "docker") ]]; then 
        echo "docker found." 
        export ARCION_DOCKER="docker"

        # docker is up and running
        docker ps --all >/dev/null || abort "docker is not running.  Please start docker"

        # docker version >= 19.3.0
        readarray -d ' ' ARCION_DOCKER_VERSION < <(docker version --format '{{.Client.Version}}' | awk -F'.' '{printf "%s %s %s",$1,$2,$3}')
        if (( ${ARCION_DOCKER_VERSION[0]} <= 19 )) && (( ${ARCION_DOCKER_VERSION[1]} < 3 )); then
            abort "docker 19.3.0 or greater needed. $(echo  ${ARCION_DOCKER_VERSION[*]} | tr '[:space:]' '.') found."
        fi
        return 0
    fi

    abort "podman or docker not found."
}
createArcnet() {
    ${ARCION_DOCKER} network inspect arcnet >/dev/null 2>/dev/null
    if [[ "$?" == "0" ]]; then
        echo "${ARCION_DOCKER} network arcnet found."
    else 
        echo "${ARCION_DOCKER} network create arcnet"
        ${ARCION_DOCKER} network create arcnet >/tmp/install.$$ 2>&1
        if [[ "$?" != 0 ]]; then 
            cat /tmp/install.$$
            abort "${ARCION_DOCKER} network create arcnet failed."
        fi
    fi
}
createVolumes() {
    oravols=(db2_sqllib ora_client orafree_v2320-ramdisk orafree_v2320-src oraxe_v1840-src oraee_v1930-src oraee_v2130-src oraxe_v2130-ramdisk oraxe_v2130-src oraxe_v2130-src ora-shared-rw arcion-log) 
    for v in ${oravols[*]}; do
        ${ARCION_DOCKER} volume inspect $v >/dev/null 2>/dev/null
        if [[ "$?" = "0" ]]; then
            echo "${ARCION_DOCKER} volume $v found."
        else
            echo "${ARCION_DOCKER} volume create $v"
            ${ARCION_DOCKER} volume create $v >/tmp/install.$$ 2>&1
            if [[ "$?" != 0 ]]; then 
                cat /tmp/install.$$
                abort "${ARCION_DOCKER} create $v failed."
            fi
        fi    
    done
}
pullDockerDev() {
    if [[ -n "$DOCKERDEV_INSTALL" ]]; then
        echo "dir ${DOCKERDEV_NAME} found. running git pull to refresh"
        if [ -z "${ARCION_WORKLOADS_TAG}" ]; then
            git fetch
        else
            git config pull.rebase false
            git pull origin ${ARCION_WORKLOADS_TAG}
            git switch ${ARCION_WORKLOADS_TAG}
        fi
        popd
    else
        echo "git clone https://github.com/arcionlabs/${DOCKERDEV_NAME} ."
        git clone https://github.com/arcionlabs/${DOCKERDEV_NAME} . >/tmp/install.$$ 2>&1
        if [[ "$?" != 0 ]]; then 
            cat /tmp/install.$$
            abort "git clone https://github.com/arcionlabs/${DOCKERDEV_NAME} failed."
        fi
    fi
}
pullArcdemo() {
    # pull 
    $ARCION_DOCKER_COMPOSE -f ${DOCKERDEV_BASEDIR}/arcdemo/docker-compose.yaml pull || abort "please see the error msg"
}

startDatabases() {
    echo ${ARCION_DOCKER_DBS[@]}
    for db in ${ARCION_DOCKER_DBS[@]}; do
        readarray -d',' -t name_ver_onoff < <(echo "${db}" | awk -F',' 'NF==2 {printf "%s,,%s",$1,$2} NF==3 {printf "%s,%s,%s",$1,$2,$3}')

        declare -p name_ver_onoff

        case "${name_ver_onoff[2]}" in
        "ON") docker_compose_db "up" "${name_ver_onoff[0]}" "${name_ver_onoff[1]}";;
        "OFF") docker_compose_db "stop" "${name_ver_onoff[0]}" "${name_ver_onoff[1]}";;
        *) abort "Error: expecting ON|OFF ${db} from ARCION_DOCKER_DBS=${ARCION_DOCKER_DBS[*]}";;
        esac   
    done
}
startArcdemo() {
    # configs are relative to the script
    pushd ${DOCKERDEV_BASEDIR}/arcdemo >/dev/null || abort "${DOCKERDEV_BASEDIR}/arcdemo does not exist"

    $ARCION_DOCKER_COMPOSE up -d || abort "please see the error msg"

    # start Arcion demo kit CLI
    ttyd_started=$( $ARCION_DOCKER_COMPOSE logs workloads 2>&1 | grep ttyd )
    while [ -z "${ttyd_started}" ]; do
        sleep 1
        echo "waiting on $ARCION_DOCKER_COMPOSE logs workloads 2>&1 | grep ttyd"
        ttyd_started=$( $ARCION_DOCKER_COMPOSE logs workloads 2>&1 | grep ttyd )
    done
    $ARCION_DOCKER_COMPOSE exec workloads bash -c 'tmux send-keys -t arcion:0.0 "clear" enter'
    sleep 1
    $ARCION_DOCKER_COMPOSE exec workloads bash -c 'tmux send-keys -t arcion:0.0 "arcdemo.sh full mysql pg"; tmux attach'

    popd >/dev/null || abort "startArcdemo: popd failed"
}

setMachineType
setDockerDevName
setBasedir
setWhiptailDialog
checkDocker
checkDockerCompose
(return 0 2>/dev/null) && export ARCION_INSTALL_SOURCED=1 || export ARCION_INSTALL_SOURCED=0

if (( ARCION_INSTALL_SOURCED == 0 )); then
    # choose prereq check
    if [[ -n "${DOCKERDEV_INSTALL}" ]]; then choose_start_setup; fi

    pushd $DOCKERDEV_BASEDIR >/dev/null || abort "popd to $DOCKERDEV_BASEDIR failed"

    checkArcionLicense
    checkJq
    checkGit

    createArcnet
    createVolumes

    pullDockerDev
    # choose databases
    chooseDataProviders
    startDatabases

    # choose demo run
    choose_start_cli
    startArcdemo
    popd >/dev/null
fi
