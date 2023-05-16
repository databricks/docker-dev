from erichough/nfs-server

label maintainer sangkyulee@gmail.com

# user id 1000 used by 11g container
# user id 54321 used by newer container 
run adduser -D -h /home/oracle -u 54321 oracle \ 
  && adduser -D -h /home/db2 -u 1000 db2inst1

run mkdir /export \
  && mkdir /oradata \
  && mkdir /oradata/ee \
  && mkdir /oradata/xe \
  && mkdir /oradata/rac \
  && mkdir /oradata/ee/1930 \
  && mkdir /oradata/xe/2130 \
  && mkdir /oradata/xe/11g \
  && mkdir /db2data \
  && chown -R oracle /oradata \
  && chown -R db2inst1 /oradata/xe/11g \
  && chown -R db2inst1 /db2data