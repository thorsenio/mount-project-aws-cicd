#!/usr/bin/env bash

# This script deletes the specified stack in the project's region

if [[ $# -lt 1 || $# -gt 2 ]]
then
  echo "Usage: $0 STACK_NAME [REGION]" 1>&2
  exit 1
fi

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../aws-functions.sh
source ../../../compute-variables.sh

STACK_NAME=$1
REGION=${2:-${Region}}

echo "Requesting deletion of the '${STACK_NAME}' stack..."
OUTPUT=$(aws cloudformation delete-stack \
  --profile ${Profile} \
  --region ${REGION} \
  --stack-name ${STACK_NAME} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${REGION} ${EXIT_STATUS} ${OUTPUT}
