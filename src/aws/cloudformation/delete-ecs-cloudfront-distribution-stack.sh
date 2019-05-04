#!/usr/bin/env bash

# This script deletes the specified CloudFront distribution stack

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../compute-variables.sh

STACK_NAME=${CloudfrontDistributionStackName}

# If the bucket exists, empty it; otherwise, CloudFormation won't be able to delete it
../s3/empty-bucket.sh ${ProjectBucketName} 'site'
exitOnError $? "Deletion of the '${STACK_NAME}' stack has been aborted."

helpers/delete-stack.sh ${STACK_NAME}
exitOnError $?
