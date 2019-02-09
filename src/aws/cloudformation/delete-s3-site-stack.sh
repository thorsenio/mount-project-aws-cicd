#!/usr/bin/env bash

# This script deletes the specified S3 site stack

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# If the bucket exists, empty it; otherwise, CloudFormation won't be able to delete it
BUCKET_NAME=$(echoSiteBucketName ${PROFILE} ${Region} ${SiteStackName})

bucketExists ${PROFILE} ${BUCKET_NAME}
if [[ $? -eq 0 ]]
then
  # The bucket exists, so empty it
  echo 'Emptying site bucket...'
  ../s3/empty-site-bucket.sh ${BUCKET_NAME}

  if [[ $? -ne 0 ]]
  then
    echo 'The site bucket could not be emptied.'
    echo 'Deletion of the stack has been aborted.'
    exit 1
  fi
fi

echo 'Requesting deletion of the stack...'
OUTPUT=$(aws cloudformation delete-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${SiteStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${Region} ${EXIT_STATUS} ${OUTPUT}
