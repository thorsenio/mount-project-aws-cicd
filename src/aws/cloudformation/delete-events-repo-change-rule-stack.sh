#!/usr/bin/env bash

# This script deletes the specified Events rule stack

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

OUTPUT=$(aws cloudformation delete-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${EventsRepoChangeRuleStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${Region} ${EXIT_STATUS} ${OUTPUT}

