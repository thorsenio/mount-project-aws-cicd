#!/usr/bin/env bash

# This script creates an S3 bucket in the project's region that redirects to a domain name.
# It assumes that the same account already has a Route 53 hosted zone for the source domain.

if [[ $# -lt 3 ]]
then
  echo "Usage: $0 SOURCE_DOMAIN_NAME TARGET_DOMAIN_NAME STACK_NAME [OPTIONS]" 1>&2
  exit 1
fi

SOURCE_DOMAIN_NAME=$1
TARGET_DOMAIN_NAME=$2
STACK_NAME=$3
shift 3

CLOUDFORMATION_TEMPLATE='templates/http-redirection-bucket.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source include/parse-stack-operation-options.sh "$@"
source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used to put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${STACK_NAME})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${STACK_NAME} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=SourceDomainName,ParameterValue=${SOURCE_DOMAIN_NAME} \
    ParameterKey=TargetDomainName,ParameterValue=${TARGET_DOMAIN_NAME} \
)

echoPutStackOutput ${STACK_NAME} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?

if [[ ${WAIT} == true ]]; then
  awaitStackOperationComplete ${Profile} ${Region} ${PUT_MODE} ${STACK_NAME}
  exitOnError $?
fi
