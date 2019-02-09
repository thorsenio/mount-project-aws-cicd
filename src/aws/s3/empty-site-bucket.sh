#!/usr/bin/env bash

if [[ ${#} -lt 1 ]]
then
  echo "Usage: ${0} BUCKET_NAME" >&2
  exit 1
fi

BUCKET_NAME=${1}

# Change to the directory of this script
cd $(dirname "$0")

source functions.sh
source variables-computed.sh

aws s3 rm s3://${BUCKET_NAME}/ \
  --profile ${PROFILE} \
  --recursive

if [[ $? -ne 0 ]]
then
  exit 1
fi
