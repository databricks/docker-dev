#!/usr/bin/env bash

# replace with the script that fixed the missing last line
cp /docker-entrypoint-initdb.d/RUN_MYSYBASE /opt/sybase/ASE-16_0/install/. 

# run sybase
/sybase-entrypoint.sh
