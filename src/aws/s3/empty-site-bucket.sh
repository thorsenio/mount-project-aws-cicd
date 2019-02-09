#!/usr/bin/env bash

# This script empties the specified S3 bucket

if [[ ${#} -lt 1 || ${#} -gt 2 ]]
then
  echo "Usage: ${0} BUCKET_NAME [PROFILE]" >&2
  exit 1
fi

BUCKET_NAME=${1}
if [[ ${#} -eq 2 ]]
then
  PROFILE=${2}
else
  PROFILE='default'
fi

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

aws s3 rm s3://${BUCKET_NAME}/ \
  --profile ${PROFILE} \
  --recursive

if [[ $? -ne 0 ]]
then
  exit 1
fi
