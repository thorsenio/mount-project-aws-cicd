#!/usr/bin/env bash

# This script updates a stack if it exists or creates the stack if it doesn't exist

CLOUDFORMATION_TEMPLATE='./cicd-pipeline.yml'

# Change to the directory of this script
cd $(dirname "$0")

source functions.sh
source variables-computed.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${CodeBuildProjectStackName})

# TODO: REFACTOR: Use a function to generate ParameterKey,ParameterValue strings

./package.sh ${CLOUDFORMATION_TEMPLATE}

if [[ $? -ne 0 ]]
then
  exit 1
fi

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d. -f1)

# Check whether the CodePipeline service role exists, and pass the value to the template.
iamRoleExists ${PROFILE} ${Region} ${CodePipelineServiceRoleName}
if [[ $? == '0' ]]
then
  CP_SERVICE_ROLE_EXISTS=true
else
  CP_SERVICE_ROLE_EXISTS=false
fi

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${CodePipelineStackName} \
  --template-body file://${TEMPLATE_BASENAME}--expanded.yml \
  --parameters \
    ParameterKey=CodeBuildArtifactBucketName,ParameterValue=${CodeBuildArtifactBucketName} \
    ParameterKey=CodeBuildProjectName,ParameterValue=${CodeBuildProjectName} \
    ParameterKey=CodePipelineArtifactBucketName,ParameterValue=${CodePipelineArtifactBucketName} \
    ParameterKey=CodePipelineName,ParameterValue=${CodePipelineName} \
    ParameterKey=CodePipelineServiceRoleExists,ParameterValue=${CP_SERVICE_ROLE_EXISTS} \
    ParameterKey=CodePipelineServiceRoleName,ParameterValue=${CodePipelineServiceRoleName} \
    ParameterKey=EventsRuleRandomId,ParameterValue=${EventsRuleRandomId} \
    ParameterKey=ProjectDescription,ParameterValue="${ProjectDescription}" \
    ParameterKey=ProjectName,ParameterValue=${ProjectName} \
    ParameterKey=RepoName,ParameterValue=${RepoName} \
    ParameterKey=SiteBucketName,ParameterValue=${SiteBucketName} \
  --capabilities \
    CAPABILITY_AUTO_EXPAND \
    CAPABILITY_IAM \
    CAPABILITY_NAMED_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
