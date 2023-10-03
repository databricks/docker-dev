from container-registry.oracle.com/database/express:18.4.0-xe

label maintainer sangkyulee@gmail.com

# for sharing data with arcion 
user root
run mkdir -p ${ORACLE_BASE}/oradata/share
run chown oracle:oinstall ${ORACLE_BASE}/oradata/share

run mkdir -p ${ORACLE_BASE}/oradata/archive_logs
run chown oracle:oinstall ${ORACLE_BASE}/oradata/archive_logs

run mkdir -p ${ORACLE_BASE}/oradata/online_logs
run chown oracle:oinstall ${ORACLE_BASE}/oradata/online_logs

# switch user back to oracle
# 18 runs as root
# user oracle
