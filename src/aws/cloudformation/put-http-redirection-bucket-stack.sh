#!/usr/bin/env bash

# This script creates an S3 bucket that redirects to a domain name. It assumes that the same
# account already has a Route 53 hosted zone for the source domain.

if [[ $# -ne 5 ]]
then
  echo "Usage: $0 PROFILE REGION SOURCE_DOMAIN_NAME TARGET_DOMAIN_NAME STACK_NAME" >&2
  exit 1
fi

PROFILE=$1
REGION=$2
SOURCE_DOMAIN_NAME=$3
TARGET_DOMAIN_NAME=$4
STACK_NAME=$5

CLOUDFORMATION_TEMPLATE='templates/http-redirection-bucket.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh

# Capture the mode that should be used to put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${REGION} ${STACK_NAME})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${REGION} \
  --stack-name ${STACK_NAME} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=SourceDomainName,ParameterValue=${SOURCE_DOMAIN_NAME} \
    ParameterKey=TargetDomainName,ParameterValue=${TARGET_DOMAIN_NAME} \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${REGION} ${EXIT_STATUS} ${OUTPUT}
