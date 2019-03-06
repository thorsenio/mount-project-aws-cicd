#!/usr/bin/env bash

# This script deletes the specified S3 site stack

# TODO: REFACTOR: Make this script generic, so that it can be used to delete any stack
#  that has an S3 bucket.

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# If the bucket exists, empty it; otherwise, CloudFormation won't be able to delete it
../s3/empty-bucket.sh ${ProjectBucketName} 'site'
if [[ $? -ne 0 ]]
then
  echo 'Deletion of the stack has been aborted.'
  exit 1
fi

echo 'Requesting deletion of the stack...'
OUTPUT=$(aws cloudformation delete-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${SiteStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${Region} ${EXIT_STATUS} ${OUTPUT}
