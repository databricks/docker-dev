#!/usr/bin/env bash

source /opt/sybase/SYBASE.sh

cli_user() {
    sqlplus -U ${REPLICANT_USER} -P ${REPLICANT_PW} -S $SYBASE_SID
}

cli_root() {
    isql -U $SYBASE_ROOT -P  $SYBASE_PASSWORD -S $SYBASE_SID 
}

create_heartbeat() {

    cat <<EOF | cli_root
disk resize name='master', size='30000m'
go

create database io_blitzz on master = '20000M'
go

CREATE TABLE io_blitzz.dbo.replicate_io_cdc_heartbeat(
    timestamp BIGINT NOT NULL, PRIMARY KEY(timestamp))
go

EOF
}

if [ ! -f ~/01_arcion.txt ]; then
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then ROLE=SRC; else ROLE=DST; fi

    create_dataspace
    if [[ "${ROLE^^}" = "SRC" ]]; then
        create_heartbeat | tee -a  ~/01_arcion.txt
    fi
fi
