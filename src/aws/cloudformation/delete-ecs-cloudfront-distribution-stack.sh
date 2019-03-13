#!/usr/bin/env bash

# This script deletes the specified CloudFront distribution stack

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
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${CloudfrontDistributionStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${Region} ${EXIT_STATUS} ${OUTPUT}
