from alpine

label maintainer sangkyulee@gmail.com

run mkdir /oradata \
  && mkdir /db2data
  
# match oracle
run adduser -D -h /home/oracle -u 54321 oracle \ 
  && chown oracle:oracle /oradata

run adduser -D -h /home/db2 -u 1000 db2inst1 \
  && chown db2inst1:db2inst1 /db2data
