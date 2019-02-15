#!/usr/bin/env bash

# This script updates a stack if it exists or creates the stack if it doesn't exist

CLOUDFORMATION_TEMPLATE='templates/codepipeline.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${CodePipelineStackName})

# TODO: REFACTOR: Use a function to generate ParameterKey,ParameterValue strings

./package.sh ${CLOUDFORMATION_TEMPLATE}

if [[ $? -ne 0 ]]
then
  exit 1
fi

# TODO: REFACTOR: This snippet is duplicated in `put-codebuild-project-stack.sh`
codecommitRepoExists ${PROFILE} ${Region} ${RepoName}
if [[ $? -eq 0 ]]
then
  echo "The CodeCommit repository '${RepoName}' exists and will be used for this project."
else
  ../codecommit/create-repository.sh
  if [[ $? -ne 0 ]]
  then
    exit 1
  fi
fi

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d. -f1)

# Check whether the CodePipeline service role exists, and pass a boolean to the template.
iamRoleExists ${PROFILE} ${Region} ${CodePipelineServiceRoleName}
if [[ $? -eq 0 ]]
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
    ParameterKey=AssetBucketName,ParameterValue=${AssetBucketName} \
    ParameterKey=CodeBuildArtifactBucketName,ParameterValue=${CodeBuildArtifactBucketName} \
    ParameterKey=CodeBuildEnvironmentImage,ParameterValue=${CodeBuildEnvironmentImage} \
    ParameterKey=CodeBuildProjectName,ParameterValue=${CodeBuildProjectName} \
    ParameterKey=CodeBuildServiceRoleName,ParameterValue=${CodeBuildServiceRoleName} \
    ParameterKey=CodeBuildServiceRolePolicyName,ParameterValue=${CodeBuildServiceRolePolicyName} \
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
