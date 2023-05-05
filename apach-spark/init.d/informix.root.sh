#!/usr/bin/env bash

# setup for basic
# LOG MODE ANSI does not allow remote connection
# https://www.ibm.com/docs/en/informix-servers/14.10?topic=statement-ansi-compliant-databases
onmode -wf USERMAPPING=BASIC
[ ! -d /etc/informix ] && sudo mkdir -p /etc/informix
# allow remote login for users
sudo echo "arcion-demo.arcnet" >>  $INFORMIXDIR/etc/hosts.equiv
# create host user and set database password
# create utf8 compitable database
# export GL_USEGLU=1

while read -r line; do
  user=$( echo $line | awk '{print $1}')
  password=$( echo $line | awk '{print $2}')
  echo $user >> ~/.rhosts 
  sudo useradd -d /home/$user -s /bin/false $user
  sudo tee -a /etc/informix/allowed.surrogates <<< "USER:$user"
  echo "create user $user with password '$password';" | dbaccess
  echo "create database IF NOT EXISTS $user with LOG;" | dbaccess
  echo "grant resource to $user;" | dbaccess $user
  echo "grant connect to $user;" | dbaccess $user
done << EOF
arcsrc Passw0rd
arcdst Passw0rd
EOF
# make the users available
onmode -cache surrogates
#loading cdc prerequisite
dbaccess - $INFORMIXDIR/etc/syscdcv1.sql
echo "CDC prerequisite sql loaded..."