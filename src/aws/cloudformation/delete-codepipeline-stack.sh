#!/usr/bin/env bash

# This script deletes the specified CloudFormation stack

# Change to the directory of this script
cd $(dirname "$0")

source functions.sh
source variables-computed.sh

aws cloudformation delete-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${CodePipelineStackName}
