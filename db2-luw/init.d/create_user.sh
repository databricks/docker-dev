#!/usr/bin/env bash

while read -r line; do
  user=$( echo $line | awk '{print $1}')
  password=$( echo $line | awk '{print $2}')
  useradd -g db2iadm1 -m -d /home/$user $user
  echo $user:$password | chpasswd
done << EOF
arcsrc Passw0rd
arcdst Passw0rd
EOF

# /database/data/db2inst1/NODE0000 has arcsrc and arcdst databases
su --login db2inst1
  db2 CREATE DATABASE ARCSRC
  db2 CREATE DATABASE ARCDST


  connect to arcsrc
  grant dataaccess on database to user arcsrc
  grant load on database to user arcsrc


  connect to arcdst;
  grant dataaccess on database to user arcdst
  grant load on database to user arcdst
