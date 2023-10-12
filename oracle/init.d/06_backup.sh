#!/usr/bin/env bash

backup() {

    mkdir -p ${ORACLE_BASE}/oradata/backup

    rman target / << EOF
    shutdown immediate;
    startup mount;
    CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${ORACLE_BASE}/oradata/backup/full_%u_%s_%p';
    BACKUP AS BACKUPSET DATABASE;
    alter database open;
EOF

    sqlplus -S sys/${ORACLE_PWD}@${ORACLE_SID} as sysdba <<'EOF' | tee -a $LOGDIR/backup.log
    set markup csv on
    select current_scn from v$database;
EOF
}


echo "Checking $LOGDIR/backup.log this script already ran"
if [ -f "$LOGDIR/backup.log" ]; then 
    echo "skipping."
else
    backup | tee -a $LOGDIR/backup.log
fi
