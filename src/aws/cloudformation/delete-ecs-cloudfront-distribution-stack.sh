#!/usr/bin/env bash

# This script deletes the specified CloudFront distribution stack

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

OUTPUT=$(aws cloudformation delete-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${CloudfrontDistributionStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${Region} ${EXIT_STATUS} ${OUTPUT}
