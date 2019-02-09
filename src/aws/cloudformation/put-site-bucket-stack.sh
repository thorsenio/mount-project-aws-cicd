#!/usr/bin/env bash

# This script uses CloudFormation to create an S3 bucket to host the project's website files.

# Typically, this script should be used only to test the template. Ordinarily, the bucket stack
# is created as a nested stack within the S3 site stack.

# There is no `delete-site-bucket-stack.sh`, because the bucket & stack get unique names
# and these are not stored anywhere, so the deletion script would have no way of knowing which
# bucket to delete.

CLOUDFORMATION_TEMPLATE='templates/site-bucket.yml'

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

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
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=SiteErrorDocument,ParameterValue=${SiteErrorDocument} \
    ParameterKey=SiteIndexDocument,ParameterValue=${SiteIndexDocument} \
    ParameterKey=SiteBucketName,ParameterValue=${SiteBucketName} \
    ParameterKey=SiteDomainName,ParameterValue=${SiteDomainName} \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
