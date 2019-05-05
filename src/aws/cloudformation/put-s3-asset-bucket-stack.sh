#!/usr/bin/env bash

# This script uses CloudFormation to create an S3 bucket to host the project's assets.

# Unlike `put-site-bucket-stack.sh`, this script doesn't configure the S3 bucket as a website.

# TODO: REFACTOR: Reduce code duplication with `put-site-bucket-stack.sh`.

CLOUDFORMATION_TEMPLATE='templates/s3-asset-bucket.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source include/parse-stack-operation-options.sh "$@"
source ../aws-functions.sh
source ../../compute-variables.sh

STACK_NAME=${ProjectBucketStackName}

# Skip creation of the bucket if it already exists
if bucketExists ${Profile} ${ProjectBucketName}; then
  exit 0
fi

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${STACK_NAME})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${STACK_NAME} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=BucketName,ParameterValue=${ProjectBucketName} \
)

echoPutStackOutput ${STACK_NAME} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?

if [[ ${WAIT} == true ]]; then
  awaitStackOperationComplete ${Profile} ${Region} ${PUT_MODE} ${STACK_NAME}
  exitOnError $?
fi
