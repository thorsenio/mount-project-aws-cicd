#!/usr/bin/env bash

# This script configures the specified S3 bucket to redirect to the specified host

if [[ $# -lt 2 ]]
then
  echo "Usage: ${0} BUCKET_NAME HOST_NAME" >&2
  exit 1
fi

# Required arguments
BUCKET_NAME=$1
HOST_NAME=$2

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

if ! bucketExists ${Profile} ${BUCKET_NAME}; then
  echo "The ${BUCKET_NAME} bucket does not exist." 1>&2
  exit 1
fi

# Set the bucket's access-control list (ACL) to allow read access by anyone
aws s3api put-bucket-acl \
  --profile ${Profile} \
  --bucket ${BUCKET_NAME} \
  --acl public-read


if [[ $? -ne 0 ]]
then
  echo 'The ACL could not be set to PublicRead' 1>&2
  exit 1
fi

read -r -d '' WEBSITE_CONFIGURATION <<-EOF
  {
    "RedirectAllRequestsTo": {
      "HostName": "${HOST_NAME}",
      "Protocol": "https"
    }
  }
EOF

aws s3api put-bucket-website \
  --profile ${Profile} \
  --bucket ${BUCKET_NAME} \
  --website-configuration "${WEBSITE_CONFIGURATION}"

if [[ $? -eq 0 ]]; then
  echo "The '${BUCKET_NAME}' bucket has been configured to redirect to https://${HOST_NAME}"
else
  echo 'The bucket website configuration could not be set' 1>&2
  exit 1
fi
