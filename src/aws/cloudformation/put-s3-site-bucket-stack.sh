#!/usr/bin/env bash

# This script uses CloudFormation to create an S3 bucket to host the project's website files.

# Typically, this script should be used only to test the template. Ordinarily, the bucket stack
# is created as a nested stack within the S3 site stack.

# There is no `delete-site-bucket-stack.sh`, because the bucket & stack get unique names
# and these are not stored anywhere, so the deletion script would have no way of knowing which
# bucket to delete. If it's necessary to have a deletion script, use Outputs to create a
# persistent reference.

CLOUDFORMATION_TEMPLATE='templates/s3-site-bucket.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Skip creation of the bucket if it already exists
if bucketExists ${PROFILE} ${ProjectBucketName}; then
  exit 0
fi

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${ProjectBucketStackName})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${ProjectBucketStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=BucketName,ParameterValue=${ProjectBucketName} \
    ParameterKey=ErrorDocument,ParameterValue=${SiteErrorDocument} \
    ParameterKey=IndexDocument,ParameterValue=${SiteIndexDocument} \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
