#!/usr/bin/env bash

echo "checking if $MONGO_KEYFILE_DIR/mongodb.keyfile exists"
if [ ! -f "$MONGO_KEYFILE_DIR/mongodb.keyfile" ]; then
    openssl rand -base64 756 > $MONGO_KEYFILE_DIR/mongodb.keyfile
    chmod 400 $MONGO_KEYFILE_DIR/mongodb.keyfile
else
    echo "exists. skipping"
fi