#!/usr/bin/env bash

TEMPLATE_FILE='./site-bucket.yml'

# Change to the directory of this script
cd $(dirname "$0")

source functions.sh
source variables-computed.sh

# Skip creation of the bucket if it already exists
bucketExists ${PROFILE} ${SiteBucketName}
ERROR_STATUS=$?
if [[ ${ERROR_STATUS} -eq 0 ]]
then
  exit 0
fi

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${SiteBucketStackName})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${SiteBucketStackName} \
  --template-body file://${TEMPLATE_FILE} \
  --parameters \
    ParameterKey=SiteErrorDocument,ParameterValue=${SiteErrorDocument} \
    ParameterKey=SiteIndexDocument,ParameterValue=${SiteIndexDocument} \
    ParameterKey=SiteBucketName,ParameterValue=${SiteBucketName} \
    ParameterKey=SiteDomainName,ParameterValue=${SiteDomainName} \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
