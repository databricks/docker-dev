#!/usr/bin/env bash

PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
. ${PROG_DIR}/utils.sh

# cut and paste from
# https://github.com/microsoft/mssql-docker/blob/master/linux/preview/examples/mssql-customize/entrypoint.sh
start_db() {
  /opt/mssql/bin/sqlservr &
}

# cut and paste from
# https://github.com/microsoft/mssql-docker/blob/master/linux/preview/examples/mssql-customize/configure-db.sh
wait_for_db() {
  # Wait 60 seconds for SQL Server to start up by ensuring that 
  # calling SQLCMD does not return an error code, which will ensure that sqlcmd is accessible
  # and that system and user databases return "0" which means all databases are in an "online" state
  # https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-databases-transact-sql?view=sql-server-2017 

  local DBSTATUS=1
  local ERRCODE=1
  local i=0

  while [[ $DBSTATUS -ne 0 || $ERRCODE -ne 0 ]] && [[ $i -lt 60 ]]; do
    sleep 1
    i=$i+1
    DBSTATUS=$(/opt/mssql-tools/bin/sqlcmd -h -1 -t 1 -U sa -P $MSSQL_SA_PASSWORD -Q "SET NOCOUNT ON; Select SUM(state) from sys.databases")
    ERRCODE=$?
    echo "DBSTATUS=$DBSTATUS"
    echo "ERRCODE=$ERRCODE"
    echo "Waiting for SQL Server to start"
  done

  if [[ $DBSTATUS -ne 0 || $ERRCODE -ne 0 ]]; then 
    echo "SQL Server took more than 60 seconds to start up or one or more databases are not in an ONLINE state"
    exit 1
  fi
}

start_db
wait_for_db

# initialize startup scripts
echo "Starting /docker-entrypoint-initdb.d scripts"
if [ -f ${INITDB_LOG_DIR}/docker-entrypoint-initdb.d.started ]; then
  echo "ran before. skipping"
else
  THIS_SCRIPT=$(basename $0)
  for f in $(find ${INITDB_DIR} -maxdepth 1 ! -name "$THIS_SCRIPT" -name "*.sh" -type f -executable | sort); do
      echo "Starting $f"
      $f
      echo "Finished $f"
  done
  touch ${INITDB_LOG_DIR}/docker-entrypoint-initdb.d.started
fi
echo "Finished /docker-entrypoint-initdb.d scripts"

# background process that started should never finish
# otherwise, the docker will exit
wait