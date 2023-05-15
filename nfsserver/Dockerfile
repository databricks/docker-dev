from erichough/nfs-server

label maintainer sangkyulee@gmail.com

run adduser -D -h /home/oracle -u 54321 oracle \ 
  && adduser -D -h /home/db2 -u 1000 db2inst1

run mkdir /export \
  && mkdir /oraxe \
  && mkdir /oraee \
  && mkdir /orarac \
  && mkdir /db2data \
  && chown oracle:oracle /oraxe \
  && chown oracle:oracle /oraee \
  && chown oracle:oracle /orarac \
  && chown db2inst1:db2inst1 /db2data
