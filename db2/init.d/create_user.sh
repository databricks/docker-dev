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
done << EOF
arcsrc Passw0rd
arcdst Passw0rd
EOF