#!/usr/bin/env bash

function create_arcion_bin_volume () {
    local ARCION_BIN_URL=$1
    [ -z "${1}" ] && echo "please enter URL as param." && return 1
    local VER=$(echo $ARCION_BIN_URL | sed 's/.*cli-\(.*\)\.zip$/\1/' | sed 's/\.//g')
    docker volume create arcion-bin-$VER
    docker run -it --rm -v arcion-bin-$VER:/arcion -e ARCION_BIN_URL="$ARCION_BIN_URL" alpine sh -c '\
    cd /arcion;\
    wget $ARCION_BIN_URL;\
    unzip -q *.zip;\
    mv replicant-cli/* .;\
    rm -rf replicant-cli/;\
    rm *.zip;\
    chown -R 1000 .;\
    ls\
    '
}

create_arcion_bin_volume $*
