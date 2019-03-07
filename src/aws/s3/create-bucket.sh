#!/usr/bin/env bash

# This script creates an S3 bucket in the project's region
if [[ $# -lt 1 ]]
then
  echo "Usage: $0 BUCKET_NAME" >&2
  exit 1
fi

# Required arguments
BUCKET_NAME=$1

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

if bucketExists ${PROFILE} ${BUCKET_NAME}; then
  echo "The ${BUCKET_NAME} bucket already exists." 1>&2
  exit 1
fi

# Create an S3 bucket with the specified name
OUTPUT=$(aws s3 mb s3://${BUCKET_NAME} \
  --profile ${PROFILE} \
  --region ${Region} \
)

if [[ $? -ne 0 ]]
then
  echo 'The bucket could not be created' 1>&2
  exit 1
fi

echo ${OUTPUT}
