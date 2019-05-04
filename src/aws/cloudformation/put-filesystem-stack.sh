#!/usr/bin/env bash

# This script creates the project's filesystem

CLOUDFORMATION_TEMPLATE='templates/filesystem.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../config/compute-project-variables.sh

STACK_NAME=${FileSystemStackName}

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${STACK_NAME})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${STACK_NAME} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=EcsClusterName,ParameterValue=${EcsClusterName} \
    ParameterKey=FileSystemName,ParameterValue=${FileSystemName} \
    ParameterKey=PlatformCommitHash,ParameterValue=${PlatformCommitHash} \
    ParameterKey=PlatformId,ParameterValue=${PlatformId} \
    ParameterKey=PlatformVersionLabel,ParameterValue=${PlatformVersionLabel} \
    ParameterKey=ProjectCommitHash,ParameterValue=${ProjectCommitHash} \
    ParameterKey=ProjectVersionLabel,ParameterValue=${ProjectVersionLabel} \
)

echoPutStackOutput ${STACK_NAME} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?
