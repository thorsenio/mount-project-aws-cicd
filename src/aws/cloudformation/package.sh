#!/usr/bin/env bash

# This script runs `aws cloudformation package` against a CloudFormation template
# and saves the result to a file that can then be used to create the stack.

# Packaging is needed when using features that are unsupported in the templates used by
# CloudFormation, such as nested stack template files that are referenced by a relative path.

CLOUDFORMATION_TEMPLATE=${1}

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d. -f1)

if ! bucketExists ${PROFILE} ${CfTemplatesBucketName}; then
  echo "The CloudFormation templates bucket for the '${Region}' region was not found." 1>&2
  echo "Fix this by creating the regional platform stack ('${RegionalPlatformStackName}'):" 1>&2
  # TODO: USABILITY: Move scripts to more convenient path
  echo "  put-regional-platform-stack.sh"
  exit 1
fi

OUTPUT=$(aws cloudformation package \
  --profile ${PROFILE} \
  --region ${Region} \
  --template-file ${CLOUDFORMATION_TEMPLATE} \
  --s3-bucket ${CfTemplatesBucketName} \
  --output-template-file ${TEMPLATE_BASENAME}--expanded.yml \
)

if [[ $? -ne 0 ]]
then
  echo "${OUTPUT}" 1>&2
  exit 1
fi
