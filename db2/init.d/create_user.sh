#!/usr/bin/env bash

# create users for db2
while read -r line; do
  echo "creating $line"
  user=$( echo $line | awk '{print $1}')
  password=$( echo $line | awk '{print $2}')
  useradd -g db2iadm1 -m -d /home/$user $user
  echo $user:$password | chpasswd

  # create database each takes a while
  echo "su --login db2inst1 -c db2 CREATE DATABASE ${user^^}"
  su --login db2inst1 -c "db2 CREATE DATABASE ${user^^}"
  
  # add CDC  
  echo "su --login db2inst1 -c db2 update db cfg for ${user^^} using LOGARCHMETH1 LOGRETAIN"
  su --login db2inst1 -c "db2 update db cfg for ${user^^} using LOGARCHMETH1 LOGRETAIN"
  
  # cfg and confirm CDC was added  
  echo "su --login db2inst1 -c db2 get db cfg for ${user^^} | grep -i logarch"
  su --login db2inst1 -c "db2 get db cfg for ${user^^} | grep -i logarch"
  
  # start the backup
  su --login db2inst1 -c "mkdir -p /database/data/db2inst1/NODE0000/${user^^}_BACKUP"
  su --login db2inst1 -c "db2 backup db ${user^^} to /database/data/db2inst1/NODE0000/${user^^}_BACKUP"
done << EOF
arcsrc Passw0rd
arcdst Passw0rd
EOF