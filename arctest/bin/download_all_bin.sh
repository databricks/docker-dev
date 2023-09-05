#!/usr/bin/env bash

set -x
for i in $(seq 2 5); do
    wget https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.07.31.${i}.zip \
    && unzip -q replicant-cli-23.07.31.${i}.zip \
    && mv replicant-cli 23.07.31.${i}
done
set +x

for z in *.zip; do
  