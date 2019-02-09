#!/usr/bin/env bash

# This script deletes the specified CloudFormation stack

# Change to the directory of this script
cd $(dirname "$0")

source functions.sh
source variables-computed.sh

# If the bucket exists, empty it; otherwise, CloudFormation won't be able to delete it
BUCKET_NAME=$(echoSiteBucketName ${PROFILE} ${Region} ${SiteStackName})

bucketExists ${PROFILE} ${BUCKET_NAME}
if [[ $? -eq 0 ]]
then
  # The bucket exists, so empty it
  echo 'Emptying site bucket...'
  ./empty-site-bucket.sh ${BUCKET_NAME}

  if [[ $? -ne 0 ]]
  then
    echo 'Echo the site bucket could not be emptied.'
    echo 'Deletion of the stack has been aborted.'
    exit 1
  fi
fi

echo 'Requesting deletion of the stack...'
aws cloudformation delete-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${SiteStackName}
