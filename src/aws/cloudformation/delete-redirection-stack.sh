#!/usr/bin/env bash

# This script deletes the HTTPS redirection stack created by `put-https-redirection-stack.sh`

if [[ $# -ne 1 ]]
then
  echo "Usage: $0 STACK_NAME" >&2
  exit 1
fi

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

# The deletion process is the same as that for a redirection bucket
./delete-http-redirection-bucket-stack.sh $1
