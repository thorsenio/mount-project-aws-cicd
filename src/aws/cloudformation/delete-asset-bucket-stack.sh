#!/usr/bin/env bash

# This script deletes the S3 bucket stack created by `put-asset-bucket-stack.sh`

# Typically, this script should be used only to test the template. Ordinarily, the bucket stack
# is created & deleted as a nested stack within the S3 site stack.

# TODO: REFACTOR: To use a generic script based on `delete-s3-site-stack.sh` in aws-cicd

CLOUDFORMATION_TEMPLATE='templates/asset-bucket.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

../s3/empty-bucket.sh ${AssetBucketName} ${PROFILE} 'static files'
if [[ $? -ne 0 ]]
then
  echo 'Deletion of the stack has been aborted.'
  exit 1
fi

echo 'Requesting deletion of the stack...'
OUTPUT=$(aws cloudformation delete-stack \
  --profile=${PROFILE} \
  --region=${Region} \
  --stack-name=${AssetBucketStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${Region} ${EXIT_STATUS} ${OUTPUT}
