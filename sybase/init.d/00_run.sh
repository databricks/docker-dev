#!/usr/bin/env bash

PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
. ${PROG_DIR}/utils.sh

SYBASE_LOG=${INITDB_LOG_DIR}/sybase.log
cp /docker-entrypoint-initdb.d/lib/RUN_MYSYBASE /opt/sybase/ASE-16_0/install/. 

start_db() {
  /sybase-entrypoint.sh | tee $SYBASE_LOG & 
}

wait_for_db() {
  # wait for db to come up
  while [ ! -f $SYBASE_LOG ]; do 
      echo "waiting for $SYBASE_LOG to be created"
      sleep 10
  done

  while [ -z "$(grep -m 1 'Recovery complete.' $SYBASE_LOG)" ]; do
    echo "waiting for sybase recovery complete"
    sleep 10
  done 
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