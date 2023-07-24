#!/usr/bin/env bash

PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
. ${PROG_DIR}/utils.sh

src_user() {
    if [[ -z ${SRCDB_ARC_USER+x} ]]; then echo "SRCDB_ARC_USER not defined"; exit 1; else export DB_ARC_USER=$SRCDB_ARC_USER; fi
    if [[ -z ${SRCDB_ARC_PW+x} ]];   then echo "SRCDB_ARC_PW not defined"; exit 1;   else export DB_ARC_PW=$SRCDB_ARC_PW; fi
    if [[ -z ${SRCDB_DB+x} ]];   then echo "SRCDB_DB not defined"; exit 1;   else export DB_DB=$SRCDB_DB; fi

    heredoc_file ${PROG_DIR}/lib/02_root.sql | tee ${INITDB_LOG_DIR}/02_root.sql 
    cli_root < ${INITDB_LOG_DIR}/02_root.sql

    heredoc_file ${PROG_DIR}/lib/02_user.sql | tee ${INITDB_LOG_DIR}/02_user.sql
    cli_arcsrc < ${INITDB_LOG_DIR}/02_user.sql
}

dst_user() {
    if [[ -z ${DSTDB_ARC_USER+x} ]]; then echo "DSTDB_ARC_USER not defined"; exit 1; else export DB_ARC_USER=$DSTDB_ARC_USER; fi
    if [[ -z ${DSTDB_ARC_PW+x} ]];   then echo "DSTDB_ARC_PW not defined"; exit 1;   else export DB_ARC_PW=$DSTDB_ARC_PW; fi
    if [[ -z ${DSTDB_DB+x} ]];   then echo "DSTDB_DB not defined"; exit 1;   else export DB_DB=$DSTDB_DB; fi

    heredoc_file ${PROG_DIR}/lib/02_root.sql | tee ${INITDB_LOG_DIR}/02_root.sql 
    cli_root < ${INITDB_LOG_DIR}/02_root.sql
}

if [[ $(uname -a | awk '{print $2}') =~ 'src' ]]; then ROLE=SRC; else ROLE=DST; fi

if [ -f ${INITDB_LOG_DIR}/02_user.txt ]; then
    echo "$0: skipping. found ${INITDB_LOG_DIR}/02_user.txt"
else
    if [[ "${ROLE^^}" = "SRC" ]]; then
        src_user
    else
        dst_user
    fi

    touch ${INITDB_LOG_DIR}/02_user.txt
fi
