#!/usr/bin/env bash

# This script creates the S3 bucket that will be used to store the CloudFormation
# templates uploaded by `aws cloudformation package`

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "${0}")

source ../aws-functions.sh
source ../../compute-variables.sh

# TODO: Refactor the special handling of us-east-1.
#   If `LocationConstraint` is specified for that region, the operation fails with an
#   InvalidLocationConstraint error.
#   Can share code with `create-cicd-artifacts-buckets.sh`

if [[ ${Region} == 'us-east-1' ]]
then
  aws s3api create-bucket \
    --profile ${PROFILE} \
    --region ${Region} \
    --bucket ${TemplateBucketName}
else
  aws s3api create-bucket \
    --profile ${PROFILE} \
    --region ${Region} \
    --bucket ${TemplateBucketName} \
    --create-bucket-configuration LocationConstraint=${Region}
fi
