#!/usr/bin/env bash

# This script deletes the specified CloudFront distribution stack

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../compute-variables.sh

STACK_NAME=${CloudfrontDistributionStackName}

helpers/delete-stack.sh ${STACK_NAME} "$@"
exitOnError $?
