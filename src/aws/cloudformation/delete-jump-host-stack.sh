#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

OUTPUT=$(aws cloudformation delete-stack \
  --profile=${PROFILE} \
  --region=${Region} \
  --stack-name=${JumpHostStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${Region} ${EXIT_STATUS} ${OUTPUT}
