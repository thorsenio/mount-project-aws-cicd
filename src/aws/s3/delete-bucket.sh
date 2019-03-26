#!/usr/bin/env bash

# This script deletes the specified S3 bucket in the project's region
if [[ $# -ne 1 ]]
then
  echo "Usage: $0 BUCKET_NAME" >&2
  exit 1
fi

BUCKET_NAME=$1

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

aws s3api delete-bucket \
  --profile ${Profile} \
  --bucket ${BUCKET_NAME}

if [[ $? -ne 0 ]]; then
  exit 1
fi
