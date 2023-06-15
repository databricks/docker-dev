#!/bin/bash

test1() {
  echo "${*@Q}"
}

test1 a b "c d"
