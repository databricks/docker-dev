#!/usr/bin/env bash

# pass argument to to not run (mainly for testing)
if [[ -z "${1}" ]]; then
    if [ ! -f ${LOGDIR}/05_archive_dir.txt ]; then
        mkdir -p /var/lib/postgresql/data/wal_archive 2>&1 | tee -a ${LOGDIR}/05_archive_dir.txt
    fi
fi