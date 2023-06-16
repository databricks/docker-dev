#!/usr/bin/env bash

docker ps --format '{{.Names}}'

SELECTED=$( whiptail --title "Select database to start" \
    --checklist \
    "List of databases" 0 0 0 \
    $( for d in $(find * -maxdepth 2 -name "docker-compose.yaml" -printf "%h\n" | grep -v arcion-demo); do echo $d $d OFF; done ) \
 3>&1 1>&2 2>&3 )

for db in ${SELECTED[@]}; do
    echo $db
    pushd $(echo ${db} | sed 's/"//g' ) # remove the quote surrounding the name
    docker compose up -d
    popd
done
