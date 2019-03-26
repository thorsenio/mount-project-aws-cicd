#!/usr/bin/env bash

# This script empties the specified S3 bucket in the project's region

if [[ $# -lt 1 || $# -gt 2 ]]
then
  echo "Usage: $0 BUCKET_NAME [DESCRIPTION]" >&2
  exit 1
fi

# Required arguments
BUCKET_NAME=$1

# Optional argument
if [[ $# -eq 2 ]]
then
  DESCRIPTION="$2"
else
  DESCRIPTION='S3'
fi

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

if bucketExists ${Profile} ${BUCKET_NAME}; then
  # The bucket exists, so empty it
  echo "Emptying the '${BUCKET_NAME}' bucket..."

  aws s3 rm s3://${BUCKET_NAME}/ \
    --profile ${Profile} \
    --only-show-errors \
    --recursive

  if [[ $? -ne 0 ]]
  then
    echo "The ${DESCRIPTION} bucket could not be emptied." 1>&2
    exit 1
  fi
else
  echo "The ${DESCRIPTION} bucket does not exist." 1>&2
fi
