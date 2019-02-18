#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

GLOBAL_REGION='us-east-1'

OUTPUT=$(aws cloudformation delete-stack \
  --profile=${PROFILE} \
  --region=${GLOBAL_REGION} \
  --stack-name=${GlobalPlatformStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${GLOBAL_REGION} ${EXIT_STATUS} ${OUTPUT}
