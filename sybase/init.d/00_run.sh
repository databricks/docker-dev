#!/usr/bin/env bash

# replace with the script that fixed the missing last line
cp /docker-entrypoint-initdb.d/RUN_MYSYBASE /opt/sybase/ASE-16_0/install/. 

# run sybase
SYBASE_DATA=/opt/sybase/data
SYBASE_LOG=/opt/sybase/ASE-16_0/install/MYSYBASE.log

/sybase-entrypoint.sh | tee ${SYBASE_DATA}/sybase.log &
# wait for db to come up
while [ ! -f $SYBASE_LOG ]; do 
    echo "waiting for $SYBASE_LOG to be created"
    sleep 10
done

while [ -z "$(grep -m 1 'Recovery complete.' $SYBASE_LOG)" ]; do
  echo "waiting for sybase recovery complete"
  sleep 10
done

# initialize 
echo "Staring /docker-entrypoint-initdb.d scripts"
THIS_SCRIPT=$(basename $0)
if [ -f ${SYBASE_DATA}/docker-entrypoint-initdb.d.started ]; then
  echo "ran before. skipping"
else
  for f in $(find /docker-entrypoint-initdb.d/ ! -name "$THIS_SCRIPT" -type f); do
      echo "$f"
      $f
  done
  touch ${SYBASE_DATA}/docker-entrypoint-initdb.d.started
fi

tail -f $SYBASE_LOG