#!/usr/bin/env bash

PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
. ${PROG_DIR}/utils.sh

if [[ -z ${REPLICANT_USER+x} ]]; then echo "REPLICANT_USER not defined"; exit 1; else export DB_ARC_USER=$REPLICANT_USER; fi
if [[ -z ${REPLICANT_PW+x} ]];   then echo "REPLICANT_PW not defined"; exit 1;   else export DB_ARC_PW=$REPLICANT_PW; fi
if [[ -z ${REPLICANT_DB+x} ]];   then echo "REPLICANT_DB not defined"; exit 1;   else export DB_DB=$REPLICANT_DB; fi

if [[ $(uname -a | awk '{print $2}') =~ 'src' ]]; then ROLE=SRC; else ROLE=DST; fi

if [ -f ${INITDB_LOG_DIR}/01_arcion.txt ]; then
    echo "$0: skipping. found ${INITDB_LOG_DIR}/01_arcion.txt"
else

    heredoc_file ${PROG_DIR}/lib/01_root.sql | tee ${INITDB_LOG_DIR}/01_root.sql 
    cli_root < ${INITDB_LOG_DIR}/01_root.sql

    if [[ "${ROLE^^}" = "SRC" ]]; then

        heredoc_file ${PROG_DIR}/lib/01_replicant.sql | tee ${INITDB_LOG_DIR}/01_replicant.sql
        cli_replicant < ${INITDB_LOG_DIR}/01_replicant.sql
    fi
    touch ${INITDB_LOG_DIR}/01_arcion.txt
fi
