#!/usr/bin/env bash

# This script creates the region-wide resources used by all deployments of the platform stack
# of the same major version

CLOUDFORMATION_TEMPLATE='templates/regional-platform.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${RegionalPlatformStackName})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${RegionalPlatformStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=CicdArtifactsBucketName,ParameterValue=${CicdArtifactsBucketName} \
    ParameterKey=PlatformCommitHash,ParameterValue=${PlatformCommitHash} \
    ParameterKey=PlatformId,ParameterValue=${PlatformId} \
    ParameterKey=PlatformVersionLabel,ParameterValue=${PlatformVersionLabel} \
  --capabilities \
    CAPABILITY_IAM \
    CAPABILITY_NAMED_IAM \
)

echoPutStackOutput ${RegionalPlatformStackName} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?
