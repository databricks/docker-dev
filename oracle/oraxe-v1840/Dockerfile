from container-registry.oracle.com/database/express:18.4.0-xe

label maintainer sangkyulee@gmail.com

# for sharing data with arcion 
user root
run mkdir -p ${ORACLE_BASE}/share
run chown oracle:dba ${ORACLE_BASE}/share

# switch user back to oracle
user oracle
