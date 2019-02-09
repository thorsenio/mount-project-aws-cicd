#!/usr/bin/env bash

# This script creates a CodeBuild project and related resources as a CloudFormation stack

CLOUDFORMATION_TEMPLATE='templates/codebuild-project.yml'

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${CodeBuildProjectStackName})

# TODO: REFACTOR: Use a function to generate ParameterKey,ParameterValue strings

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${CodeBuildProjectStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=CodeBuildProjectName,ParameterValue=${CodeBuildProjectName} \
    ParameterKey=CodeBuildArtifactBucketName,ParameterValue=${CodeBuildArtifactBucketName} \
    ParameterKey=CodePipelineArtifactBucketName,ParameterValue=${CodePipelineArtifactBucketName} \
    ParameterKey=ProjectDescription,ParameterValue="${ProjectDescription}" \
    ParameterKey=ProjectName,ParameterValue=${ProjectName} \
    ParameterKey=RepoName,ParameterValue=${RepoName} \
    ParameterKey=SiteBucketName,ParameterValue=${SiteBucketName} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
