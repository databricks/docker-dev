#!/usr/bin/env bash

manual_run=$1

# do not use `exit`.  it won't start the next script
# when run automated, the script does not work.

# 21.3.0 XE specific
export ARCHREDO=/opt/oracle/oradata/XE/arch
export REDO=/opt/oracle/oradata/XE
export PASSWORD=Passw0rd
export FOOTER_LINES=4

# the below are generic
archstatus() {
    sqlplus sys/${PASSWORD}@XE as sysdba <<'EOF'
    SELECT i.instance_name, i.thread#,
    (SELECT DISTINCT DECODE(SUBSTR(f.member, 1, 1), '+', 'ASM', 'FS')
    FROM v$log l, v$logfile f
    WHERE l.thread# = i.thread#
    AND l.group# = f.group#)
    online_type,
    (SELECT DECODE(SUBSTR(a.name, 1, 1), '+', 'ASM', 'FS')
    FROM v$archived_log a
    WHERE dest_id = 1
    AND a.thread# = i.thread#
    AND a.sequence# =
    (SELECT max(al.sequence#)
    FROM v$archived_log al
    WHERE al.thread# = a.thread#)) archived_type
    FROM gv$instance i;
EOF
}

ora_showarchdest() {
    sqlplus sys/${PASSWORD}@XE as sysdba <<'EOF'
    archive log list;
    select destination, status from v$archive_dest where status='VALID';
EOF
}

ora_shutdown() {
    sqlplus sys/${PASSWORD}@XE as sysdba <<EOF
    -- set archive
    alter system set log_archive_dest_1='LOCATION=$ARCHREDO' scope=both;
    archive log list;
    shutdown immediate;
EOF
}


ora_archenable() {
    sqlplus sys/${PASSWORD} as sysdba <<'EOF'
    -- enable archive log
    startup mount
    alter database archivelog;
    recover database until cancel;
    alter database open resetlogs;
    ALTER DATABASE FORCE LOGGING;
    archive log list;
    select group#,sequence#,bytes,archived,status from v$log;
    select group#, member from v$logfile order by group#, member;
EOF
}

# skip if already run
echo "Checking $ARCHREDO/arcion_arch.log this script already ran"
if [  -f "$ARCHREDO/arcion_arch.log" ]; then exit; fi

if [ -n "${manual_run}" ]; then
    # create archive redo log
    mkdir $ARCHREDO
    ora_showarchdest
    ora_shutdown
    sleep 10
    ora_archenable
    sleep 10
    ora_showarchdest
    archstatus
    touch $ARCHREDO/arcion_arch.log
fi