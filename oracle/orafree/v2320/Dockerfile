from oracle/database:23.2.0-free

# takes a long time to download 6GB.  a lot faster to build locally
from container-registry.oracle.com/database/free:23.3.0.0

label maintainer sangkyulee@gmail.com

# for sharing data with arcion 
user root
run mkdir -p ${ORACLE_BASE}/share
run chown oracle:dba ${ORACLE_BASE}/share

# switch user back to oracle
user oracle
