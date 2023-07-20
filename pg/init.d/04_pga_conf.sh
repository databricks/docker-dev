#!/usr/bin/env bash

# pass argument to to not run (mainly for testing)
if [[ -z "${1}" ]]; then
    if [ ! -f ${LOGDIR}/04_pga_conf.txt ]; then
        echo "host replication all 0.0.0.0/0 trust" | tee -a ${LOGDIR}/04_pga_conf.txt 
        echo "host replication all ::0/0     trust" | tee -a ${LOGDIR}/04_pga_conf.txt 
        cat  ${LOGDIR}/04_pga_conf.txt  | tee -a ${PGDATA}/pg_hba.conf
    fi
fi