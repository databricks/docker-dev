#!/usr/bin/env bash

function create_arcion_bin_volume () {
    local ARCION_BIN_URL=$1
    [ -z "${1}" ] && echo "please enter URL as param." && return 1
    local VER=$(echo $ARCION_BIN_URL | sed 's/.*cli-\(.*\)\.zip$/\1/' | sed 's/\.//g')
    docker volume create arcion-bin
    docker run -it --rm -v arcion-bin:/arcion -e VER="$VER" -e ARCION_BIN_URL="$ARCION_BIN_URL" alpine sh -c '\
    echo "Downloading $VER"; \
    mkdir -p /arcion/$VER; \
    cd /arcion/$VER; \
    rm -rf *; \
    wget $ARCION_BIN_URL;\
    unzip *.zip;\
    if [ -d replicant-cli ]; then mv replicant-cli/*; rm -rf replicant-cli/; fi; \
    rm *.zip;\
    chown -R 1000 .;\
    ls\
    '
}

create_arcion_bin_volume $*
