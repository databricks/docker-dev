#!/usr/bin/env bash

service='hana'
waitstring='Startup finished!'
while [ -z "$(docker compose logs ${service} | grep -i "${waitstring}")" ]; do
    echo "10 sec waiting for $waitstring"
    sleep 10
done