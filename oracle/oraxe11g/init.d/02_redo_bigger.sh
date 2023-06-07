#!/usr/bin/env bash

manual_run=$1

# do not use `exit`.  it won't start the next script

export ARCHREDO=/u01/app/oracle/oradata/XE/arch
export REDO=/u01/app/oracle/oradata/XE
export PASSWORD=oracle
export FOOTER_LINES=3

ora_redostatus() {
    sqlplus sys/${PASSWORD}@XE as sysdba <<'EOF' | tee /tmp/wait.$$.log 
    select group#,sequence#,bytes,archived,status from v$log;
    select group#, member from v$logfile order by group#, member;
    alter system checkpoint;
EOF
}

if [ -f "$REDO/redo.large.log" ]; then
    echo "skipping. $REDO/redo.large.log exists" 
else

######################### make redo bigger

export MINGROUP=$(echo "select min(group#) from v\$log;" | sqlplus sys/${PASSWORD}@XE as sysdba | tail -n $FOOTER_LINES | head -n 1)
echo "Min redo groups = $MINGROUP"

export GROUP=$(echo "select max(group#) from v\$log;" | sqlplus sys/${PASSWORD}@XE as sysdba | tail -n $FOOTER_LINES | head -n 1)
echo "Max redo groups = $GROUP"

echo "adding 3 more redo groups"
sqlplus sys/${PASSWORD}@XE as sysdba <<EOF
alter database add logfile group $((GROUP + 1)) '$REDO/redo$((GROUP + 1)).log' size 1G;
alter database add logfile group $((GROUP + 2)) '$REDO/redo$((GROUP + 2)).log' size 1G;
alter database add logfile group $((GROUP + 3)) '$REDO/redo$((GROUP + 3)).log' size 1G;
select group#,sequence#,bytes,archived,status from v\$log;
select group#, member from v\$logfile order by group#, member;
EOF

sleep 5

for i in $(seq $MINGROUP $GROUP);do 
    echo "switching redo group $i"
    echo "alter system switch logfile;" | sqlplus sys/${PASSWORD}@XE as sysdba
done
REDO_GROUP_TO_DROP=$(( $GROUP - $MINGROUP + 1 ))

INACTIVE_CNT=0
while (( $INACTIVE_CNT < $REDO_GROUP_TO_DROP )); do
    sleep 5
    ora_redostatus
    cat /tmp/wait.$$.log
    INACTIVE_CNT=$(cat /tmp/wait.$$.log | grep -i inactive | wc -l)
    echo "INACTIVE_CNT=$INACTIVE_CNT REDO_GROUP_TO_DROP=$REDO_GROUP_TO_DROP"
done

# drop the old redo
for i in $(seq $MINGROUP $GROUP);do 
    echo "alter database drop logfile group ${i};"
    echo "alter database drop logfile group ${i};" | sqlplus sys/${PASSWORD}@XE as sysdba
done

sleep 5
ora_redostatus

touch $REDO/redo.large.log

fi