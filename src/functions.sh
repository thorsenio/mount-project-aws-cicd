#!/usr/bin/env bash

# This file contains functions unrelated to AWS

echoRandomId () {
  local LENGTH=$1
  LENGTH=${LENGTH:='13'}
  echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${LENGTH} | head -n 1)
}

echoRandomLowercaseId () {
  local LENGTH=$1
  LENGTH=${LENGTH:='13'}
  echo $(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w ${LENGTH} | head -n 1)
}
