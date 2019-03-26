#!/usr/bin/env bash

# This script empties & deletes the specified S3 bucket in the project's region
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

./empty-bucket.sh ${BUCKET_NAME}

if [[ $? -ne 0 ]]; then
  echo "The '${BUCKET_NAME}' bucket could not be emptied." 1>&2
  exit 1
fi

./delete-bucket.sh ${BUCKET_NAME}

if [[ $? -ne 0 ]]; then
  echo "The '${BUCKET_NAME}' bucket could not be deleted." 1>&2
  exit 1
fi
