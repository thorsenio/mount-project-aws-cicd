#!/usr/bin/env bash

# This script deletes the specified S3 site stack

# TODO: REFACTOR: Make this script generic, so that it can be used to delete any stack
#  that has an S3 bucket.

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../compute-variables.sh

STACK_NAME=${S3SiteStackName}

# If the bucket exists, empty it; otherwise, CloudFormation won't be able to delete it
../s3/empty-bucket.sh ${ProjectBucketName} 'site'
exitOnError $? "Deletion of the '${STACK_NAME}' stack has been aborted."

helpers/delete-stack.sh ${STACK_NAME}
exitOnError $?
