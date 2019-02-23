#!/usr/bin/env bash

# This script empties the specified S3 bucket

if [[ ${#} -lt 2 || ${#} -gt 3 ]]
then
  echo "Usage: ${0} BUCKET_NAME PROFILE [DESCRIPTION]" >&2
  exit 1
fi

# Required arguments
BUCKET_NAME=$1
PROFILE=$2

# Optional argument
if [[ $# -eq 3 ]]
then
  DESCRIPTION="$3"
else
  DESCRIPTION='S3'
fi

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

bucketExists ${PROFILE} ${BUCKET_NAME}
if [[ $? -eq 0 ]]
then
  # The bucket exists, so empty it
  echo 'Emptying bucket...'

  aws s3 rm s3://${BUCKET_NAME}/ \
    --profile ${PROFILE} \
    --only-show-errors \
    --recursive

  if [[ $? -ne 0 ]]
  then
    echo "The ${DESCRIPTION} bucket could not be emptied."
    exit 1
  fi
fi
