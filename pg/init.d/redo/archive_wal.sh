#!/usr/bin/env bash

if [  -f /var/lib/postgresql/data/wal_archive/$1 ]; then
    if [ -d /var/lib/postgresql/online_redo ]; then
        cp /var/lib/postgresql/online_redo/$1 /var/lib/postgresql/data/wal_archive/%1
    else
        cp /var/lib/postgresql/data/pg_wal/$1 /var/lib/postgresql/data/wal_archive/%1
    fi
fi