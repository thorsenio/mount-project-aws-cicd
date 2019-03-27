#!/usr/bin/env bash

# This script deletes the S3 bucket stack created by `put-asset-bucket-stack.sh`

# Typically, this script should be used only to test the template. Ordinarily, the bucket stack
# is created & deleted as a nested stack within the S3 site stack.

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../compute-variables.sh

STACK_NAME=${ProjectBucketStackName}

# If the bucket exists, empty it; otherwise, CloudFormation won't be able to delete it
../s3/empty-bucket.sh ${ProjectBucketName} 'static files'
exitOnError $? "Deletion of the '${STACK_NAME}' stack has been aborted."

helpers/delete-stack.sh ${STACK_NAME}
exitOnError $?
