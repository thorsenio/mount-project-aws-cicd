#!/usr/bin/env bash

TEMPLATE_FILE='./cloudfront-distribution.yml'

# Change to the directory of this script
cd $(dirname "$0")

source functions.sh
source variables-computed.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${CloudfrontDistributionStackName})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${CloudfrontDistributionStackName} \
  --template-body file://${TEMPLATE_FILE} \
  --parameters \
    ParameterKey=SiteBucketName,ParameterValue=${SiteBucketName} \
    ParameterKey=SiteDomainName,ParameterValue=${SiteDomainName} \
    ParameterKey=SiteErrorDocument,ParameterValue=${SiteErrorDocument} \
    ParameterKey=SiteIndexDocument,ParameterValue=${SiteIndexDocument} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
