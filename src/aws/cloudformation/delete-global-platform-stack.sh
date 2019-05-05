#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-constants.sh
source ../../compute-variables.sh

STACK_NAME=${GlobalPlatformStackName}

../s3/empty-bucket.sh ${CfnTemplatesBucketName}
exitOnError $? "Deletion of the '${STACK_NAME}' stack has been aborted."

helpers/delete-stack.sh ${STACK_NAME} ${AWS_GLOBAL_REGION} "$@"
exitOnError $?
