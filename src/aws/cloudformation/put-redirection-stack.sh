#!/usr/bin/env bash

# This script creates an S3 bucket in the project's region that redirects to a domain name.
# It assumes that
# 1) the same account already has a Route 53 hosted zone for the source domain, and
# 2) the source domain name has a verified ACM certificate

if [[ $# -ne 3 ]]
then
  echo "Usage: $0 SOURCE_DOMAIN_NAME TARGET_DOMAIN_NAME STACK_NAME" >&2
  exit 1
fi

SOURCE_DOMAIN_NAME=$1
TARGET_DOMAIN_NAME=$2
STACK_NAME=$3

CLOUDFORMATION_TEMPLATE='templates/redirection.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# The hosted zone can be referenced by the apex domain name
SOURCE_ZONE_APEX="$(echoApexDomain ${SOURCE_DOMAIN_NAME})."

echo "Source domain apex: ${SOURCE_ZONE_APEX}"

# Capture the mode that should be used to put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${STACK_NAME})
if [[ ${PUT_MODE} == 'create' ]]; then
  ACTION_ON_FAILURE='DO_NOTHING'
else
  ACTION_ON_FAILURE='ROLLBACK'
fi

# Get the ARN of the ACM certificate for the domain name being redirected
CERTIFICATE_ARN=$(echoAcmCertificateArn ${Profile} ${SOURCE_DOMAIN_NAME})
if [[ -z ${CERTIFICATE_ARN} ]]
then
  echo "No certificate was found for the domain '${SOURCE_DOMAIN_NAME}'." 1>&2
  echo "The creation of the stack has been aborted." 1>&2
  exit 1
fi

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --on-failure ${ACTION_ON_FAILURE} \
  --stack-name ${STACK_NAME} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=AcmCertificateArn,ParameterValue=${CERTIFICATE_ARN} \
    ParameterKey=CloudFrontHostedZoneId,ParameterValue=${CLOUDFRONT_HOSTED_ZONE_ID} \
    ParameterKey=SourceDomainName,ParameterValue=${SOURCE_DOMAIN_NAME} \
    ParameterKey=SourceZoneApex,ParameterValue=${SOURCE_ZONE_APEX} \
    ParameterKey=TargetDomainName,ParameterValue=${TARGET_DOMAIN_NAME} \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
