#!/usr/bin/env bash

PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
. ${PROG_DIR}/utils.sh

if [[ -z ${SRCDB_ARC_USER+x} ]]; then echo "SRCDB_ARC_USER not defined"; exit 1; else export DB_ARC_USER=$SRCDB_ARC_USER; fi
if [[ -z ${SRCDB_ARC_PW+x} ]];   then echo "SRCDB_ARC_PW not defined"; exit 1;   else export DB_ARC_PW=$SRCDB_ARC_PW; fi
if [[ -z ${SRCDB_DB+x} ]];   then echo "SRCDB_DB not defined"; exit 1;   else export DB_DB=$SRCDB_DB; fi

if [ -f ${INITDB_LOG_DIR}/02_user.txt ]; then
    echo "$0: skipping. found ${INITDB_LOG_DIR}/02_user.txt"
else
    if [[ $(uname -a | awk '{print $2}') =~ $ ]]; then ROLE=; else ROLE=DST; fi

    heredoc_file ${PROG_DIR}/lib/02_root.sql | tee ${INITDB_LOG_DIR}/02_root.sql 
    cli_root < ${INITDB_LOG_DIR}/02_root.sql

    if [[ "${ROLE^^}" = "" ]]; then

        heredoc_file ${PROG_DIR}/lib/02_user.sql | tee ${INITDB_LOG_DIR}/02_user.sql
        cli_arcsrc < ${INITDB_LOG_DIR}/02_user.sql
    fi
    touch ${INITDB_LOG_DIR}/02_user.txt
fi
