#!/usr/bin/env bash

# run singlestore startup
bash /startup & 
S2=$!

echo "Waiting for background process $S2"
ps -aef | grep ${S2}

# wait for https to start (indicating the end of startup)
while [ -z "$(grep 'Listening on 0.0.0.0:8080' /var/lib/singlestoredb-studio/studio.log)" ]; do
  echo "waiting for /var/lib/singlestoredb-studio/studio.log"
  sleep 10
done

# initialize 
echo "Staring /docker-entrypoint-initdb.d"
for f in $(find /docker-entrypoint-initdb.d/ ! -name "00_run.sh" -type f); do
    echo "$f"
    $f
done

# dont exit as S2 will be tailing the log
echo "Waiting for background process $S2"
ps -aef | grep ${S2}

wait

echo "should not have exited"
sleep 100000