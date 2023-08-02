#!/usr/bin/env bash

test() {
local test_1=$1
local envvar=$2
echo ${!envvar}

printf -v "$test_1" '%s' ${!envvar} 
echo "x${TEST}x"
}

test TEST $2
echo $TEST
