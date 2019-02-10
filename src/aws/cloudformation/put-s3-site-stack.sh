#!/usr/bin/env bash

# This script updates a stack if it exists or creates the stack if it doesn't exist

CLOUDFORMATION_TEMPLATE='templates/s3-site.yml'

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${SiteStackName})

if [[ ${PUT_MODE} == 'update' ]]
then
  # Get the bucket name from the existing stack
  SiteBucketName=$(echoSiteBucketName ${PROFILE} ${Region} ${SiteStackName})
fi

./package.sh ${CLOUDFORMATION_TEMPLATE}

if [[ $? -ne 0 ]]
then
  exit 1
fi

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d. -f1)

# TODO: REFACTOR: Use a function to generate ParameterKey,ParameterValue strings
OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${SiteStackName} \
  --template-body file://${TEMPLATE_BASENAME}--expanded.yml \
  --parameters \
    ParameterKey=SiteBucketName,ParameterValue=${SiteBucketName} \
    ParameterKey=SiteDomainName,ParameterValue=${SiteDomainName} \
    ParameterKey=SiteErrorDocument,ParameterValue=${SiteErrorDocument} \
    ParameterKey=SiteIndexDocument,ParameterValue=${SiteIndexDocument} \
  --capabilities \
    CAPABILITY_AUTO_EXPAND \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}

if [[ ${EXIT_STATUS} -eq 0 ]]
then
  echo 'The stack will not be created unless you create (or have already created)'
  echo 'a CNAME record to allow AWS to validate the domain.'
  echo 'To display the CNAME hostname and value, run ../iam/describe-cname-record.sh'
fi