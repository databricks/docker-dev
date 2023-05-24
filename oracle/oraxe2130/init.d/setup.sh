#!/usr/bin/env bash

# 21.3.0 XE specific
export ARCHREDO=/opt/oracle/oradata/XE/arch
export REDO=/opt/oracle/oradata/XE
export PASSWORD=Passw0rd

# the below are generic
mkdir $ARCHREDO

sqlplus sys/${PASSWORD}@XE as sysdba <<EOF
-- set archive
alter system set log_archive_dest_1='LOCATION=$ARCHREDO' scope=both;
select destination, status from v\$archive_dest where status='VALID';
archive log list;
shutdown
EOF

sqlplus sys/${PASSWORD} as sysdba <<EOF
-- enable archive log
startup mount
alter database archivelog;
recover database until cancel;
alter database open resetlogs;
ALTER DATABASE FORCE LOGGING;
archive log list;
select group#,sequence#,bytes,archived,status from v\$log;
select group#, member from v\$logfile order by group#, member;
EOF


export GROUP=$(echo "select max(group#) from v\$log;" | sqlplus sys/${PASSWORD}@XE as sysdba | tail -n 3 | head -n 1)

sqlplus sys/${PASSWORD}@XE as sysdba <<EOF
alter database add logfile group $((GROUP + 1)) '$REDO/redo$((GROUP + 1)).log' size 1G;
alter database add logfile group $((GROUP + 2)) '$REDO/redo$((GROUP + 2)).log' size 1G;
alter database add logfile group $((GROUP + 3)) '$REDO/redo$((GROUP + 3)).log' size 1G;
select group#,sequence#,bytes,archived,status from v\$log;
select group#, member from v\$logfile order by group#, member;
EOF

for i in $(seq 1 $GROUP);do 
    echo "alter system switch logfile;" | sqlplus sys/${PASSWORD}@XE as sysdba
done

sqlplus sys/${PASSWORD}@XE as sysdba <<EOF
select group#,sequence#,bytes,archived,status from v\$log;
select group#, member from v\$logfile order by group#, member;
alter system checkpoint;
EOF

# drop the old redo
for i in $(seq 1 $GROUP);do 
    echo "alter database drop logfile group ${i};" | sqlplus sys/${PASSWORD}@XE as sysdba
done


# this is run by Arcion.  do not want NULLs on the output

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
