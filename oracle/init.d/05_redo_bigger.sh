#!/usr/bin/env bash

manual_run=$1

export REDO_SIZE=${REDO_SIZE:-1G}
export DATA_SIZE=${DATA_SIZE:-12000M}  # xe and free max
export UNDO_SIZE=${UNDO_SIZE:-5G}
export TEMP_SIZE=${TEMP_SIZE:-5G}

# do not use `exit`.  it won't start the next script

ora_redostatus() {
    sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<'EOF' | tee /tmp/wait.$$.log 
    set markup csv on
    select group#,sequence#,bytes,archived,status from v$log;
    select group#, member from v$logfile order by group#, member;
    alter system checkpoint;
EOF
}

######################### make redo bigger
addRedo() {

    local FOOTER_LINES=2
    export MINGROUP=$(echo "select min(group#) from v\$log;" | sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba | tail -n $FOOTER_LINES | head -n 1)
    echo "Min redo groups = $MINGROUP"

    export GROUP=$(echo "select max(group#) from v\$log;" | sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba | tail -n $FOOTER_LINES | head -n 1)
    echo "Max redo groups = $GROUP"

    echo "adding 3 more redo groups"
    sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<EOF
    set markup csv on
    alter database add logfile group $((GROUP + 1)) '$REDO/redo$((GROUP + 1)).log' size ${REDO_SIZE};
    alter database add logfile group $((GROUP + 2)) '$REDO/redo$((GROUP + 2)).log' size ${REDO_SIZE};
    alter database add logfile group $((GROUP + 3)) '$REDO/redo$((GROUP + 3)).log' size ${REDO_SIZE};
    select group#,sequence#,bytes,archived,status from v\$log;
    select group#, member from v\$logfile order by group#, member;
EOF
}

switchWaitRedo() {
    for i in $(seq $MINGROUP $GROUP);do 
        echo "alter system switch logfile"
        echo "alter system switch logfile;" | sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba
        sleep 5
    done
    REDO_GROUP_TO_DROP=$(( $GROUP - $MINGROUP + 1 ))

    INACTIVE_CNT=0
    while (( $INACTIVE_CNT < $REDO_GROUP_TO_DROP )); do
        sleep 5
        ora_redostatus
        cat /tmp/wait.$$.log
        INACTIVE_CNT=$(cat /tmp/wait.$$.log | grep -i inactive | wc -l)
        echo "wait while INACTIVE_CNT=$INACTIVE_CNT < REDO_GROUP_TO_DROP=$REDO_GROUP_TO_DROP"
    done
}

# drop the old redo
dropOldRedo() {
    for i in $(seq $MINGROUP $GROUP);do 
        echo "alter database drop logfile group ${i};"
        echo "alter database drop logfile group ${i};" | sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba
        sleep 5
    done
}

# ALTER DATABASE DATAFILE 7 RESIZE 10G;
resizeData() {
# for 12.2 and greater
sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<'EOF' | tee /tmp/dbfsize.$$.log 
set markup csv on
SELECT a.file_id
          ,b.file_name
          ,SUM(a.bytes)/1024/1024 AS "Free MB"
          ,SUM(b.bytes)/1024/1024/1024 AS "Size GB"
    FROM dba_free_space a
        ,dba_data_files b
    WHERE a.file_id=b.file_id
    GROUP BY a.file_id,b.file_name
    ORDER BY 3 DESC;
EOF

    for line in "$(cat /tmp/dbfsize.$$.log | grep users01)"; do
        echo $line
        IFS=',' read -ra id_name <<< "$line"
        echo "users01 resize ${DATA_SIZE}"
        declare -p id_name
        sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<EOF
    set markup csv on
    alter database DATAFILE ${id_name[0]} resize ${DATA_SIZE};
EOF
    done

    for line in "$(cat /tmp/dbfsize.$$.log | grep undotbs01)"; do
        echo $line
        IFS=',' read -ra id_name <<< "$line"
        echo "undotbs01 resize ${UNDO_SIZE}"
        declare -p id_name
        sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<EOF
    set markup csv on
    alter database DATAFILE ${id_name[0]} resize ${UNDO_SIZE};
EOF
    done

}

# alter database tempfile 1 resize 10G
resizeTemp() {
    # for 12.2 and greater
    sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<'EOF' | tee /tmp/tempsize.$$.log 
    set markup csv on
    SELECT file_id, file_name, bytes/1024/1025/1025 AS "Size GB"
        FROM dba_temp_files;
EOF

    for line in $(cat /tmp/tempsize.$$.log | grep temp01); do
        echo $line
        IFS=',' read -ra id_name <<< "$line"
        echo resize ${TEMP_SIZE}; 
        declare -p id_name
        sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<EOF
    set markup csv on
    alter database tempfile ${id_name[0]} resize ${TEMP_SIZE};
    SELECT file_id, file_name, bytes/1024/1025/1025 AS "Size GB"
        FROM dba_temp_files;
EOF
    done
}

setup_redo() {

    mkdir -p $REDO

    addRedo
    sleep 5

    switchWaitRedo
    dropOldRedo
    sleep 5

    resizeData
    resizeTemp

    # show one more time
    ora_redostatus
}

echo "Checking $LOGDIR/redo.large.log this script already ran"
if [  -f "$LOGDIR/redo.large.log" ]; then 
    echo "skipping."
else
    setup_redo | tee -a $LOGDIR/redo.large.log
fi