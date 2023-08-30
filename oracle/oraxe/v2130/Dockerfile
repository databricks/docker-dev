from oracle/database:21.3.0-xe

label maintainer sangkyulee@gmail.com

# for sharing data with arcion 
user root
run mkdir -p "$ORACLE_BASE"/share
run chown oracle:dba "$ORACLE_BASE"/share

# switch user back to oracle
user oracle
