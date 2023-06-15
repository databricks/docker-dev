#!/usr/bin/env bash

export USER_PREFIX=c##

cli_user() {
    sqlplus ${USER_PREFIX}${REPLICANT_USER}/${REPLICANT_PW}@${ORACLE_SID} 
}

cli_root() {
    sqlplus sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba 
}

create_heartbeat() {

    cat <<EOF | cli_root
    CREATE USER ${USER_PREFIX}${REPLICANT_USER} IDENTIFIED BY ${REPLICANT_PW};

    ALTER USER ${USER_PREFIX}${REPLICANT_USER} default tablespace USERS;

    ALTER USER ${USER_PREFIX}${REPLICANT_USER} quota unlimited on USERS;

    GRANT CREATE SESSION TO ${USER_PREFIX}${REPLICANT_USER};

    grant connect,resource to ${USER_PREFIX}${REPLICANT_USER};
    grant execute_catalog_role to ${USER_PREFIX}${REPLICANT_USER};
    grant select_catalog_role to ${USER_PREFIX}${REPLICANT_USER};

    grant dba to ${USER_PREFIX}${REPLICANT_USER};
EOF

    cat <<EOF | cli_user
        CREATE TABLE REPLICATE_IO_CDC_HEARTBEAT(
        TIMESTAMP NUMBER NOT NULL,
        PRIMARY KEY(TIMESTAMP)
        );
EOF

}

if [[ -z "${1}" ]]; then
    if [[ $(uname -a | awk '{print $2}') =~ src$ ]]; then ROLE=SRC; else ROLE=DST; fi

    if [[ "${ROLE^^}" = "SRC" ]]; then
        create_heartbeat
    fi
fi