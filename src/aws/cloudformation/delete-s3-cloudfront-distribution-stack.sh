#!/usr/bin/env bash

# This script deletes the specified CloudFront distribution stack

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../compute-variables.sh

helpers/delete-stack.sh ${CloudfrontDistributionStackName}
exitOnError $?
