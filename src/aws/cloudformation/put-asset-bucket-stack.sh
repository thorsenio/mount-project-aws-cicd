#!/usr/bin/env bash

# This script uses CloudFormation to create an S3 bucket to host the project's assets.

# Unlike `put-site-bucket-stack.sh`, this script doesn't configure the S3 bucket as a website.

# TODO: REFACTOR: Reduce code duplication with `put-site-bucket-stack.sh`.

CLOUDFORMATION_TEMPLATE='templates/asset-bucket.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Skip creation of the bucket if it already exists
bucketExists ${PROFILE} ${AssetBucketName}
ERROR_STATUS=$?
if [[ ${ERROR_STATUS} -eq 0 ]]
then
  exit 0
fi

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${AssetBucketStackName})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${AssetBucketStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=BucketName,ParameterValue=${AssetBucketName} \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
