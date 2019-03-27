#!/usr/bin/env bash

# This script creates the region-wide resources used by all deployments of the platform stack
# of the same major version

CLOUDFORMATION_TEMPLATE='templates/global-platform.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${AWS_GLOBAL_REGION} ${GlobalPlatformStackName})

if [[ $? -ne 0 ]]
then
  exit 1
fi

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d. -f1)

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${AWS_GLOBAL_REGION} \
  --stack-name ${GlobalPlatformStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=CfnTemplatesBucketName,ParameterValue=${CfnTemplatesBucketName} \
    ParameterKey=CodePipelineServiceRoleName,ParameterValue=${CodePipelineServiceRoleName} \
    ParameterKey=EcsTasksServiceRoleName,ParameterValue=${EcsTasksServiceRoleName} \
    ParameterKey=PlatformCommitHash,ParameterValue=${PlatformCommitHash} \
    ParameterKey=PlatformId,ParameterValue=${PlatformId} \
    ParameterKey=PlatformVersionLabel,ParameterValue=${PlatformVersionLabel} \
  --capabilities \
    CAPABILITY_IAM \
    CAPABILITY_NAMED_IAM \
)

echoPutStackOutput ${GlobalPlatformStackName} ${PUT_MODE} ${AWS_GLOBAL_REGION} $? ${OUTPUT}
exitOnError $?
