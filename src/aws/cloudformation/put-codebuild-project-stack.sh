#!/usr/bin/env bash

# This script creates a CodeBuild project and related resources as a CloudFormation stack

CLOUDFORMATION_TEMPLATE='templates/codebuild-project.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${CodeBuildProjectStackName})

bucketExists ${PROFILE} ${CicdArtifactsBucketName}
if [[ $? -ne 0 ]]
then
  echo 'The CI/CD artifacts bucket was not found' 1>&2
  echo "Verify that the regional platform stack ('${RegionalPlatformStackName}') is running" 1>&2
  exit 1
fi

../codecommit/put-codecommit-repository.sh ${RepoName} ${RepoDescription}

# TODO: REFACTOR: Use a function to generate ParameterKey,ParameterValue strings

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${CodeBuildProjectStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=CicdArtifactsBucketName,ParameterValue=${CicdArtifactsBucketName} \
    ParameterKey=CodeBuildEnvironmentImage,ParameterValue=${CodeBuildEnvironmentImage} \
    ParameterKey=CodeBuildProjectName,ParameterValue=${CodeBuildProjectName} \
    ParameterKey=CodeBuildServiceRoleName,ParameterValue=${CodeBuildServiceRoleName} \
    ParameterKey=CodeBuildServiceRolePolicyName,ParameterValue=${CodeBuildServiceRolePolicyName} \
    ParameterKey=DeploymentId,ParameterValue=${DeploymentId} \
    ParameterKey=ProjectBucketName,ParameterValue=${ProjectBucketName} \
    ParameterKey=ProjectDescription,ParameterValue="${ProjectDescription}" \
    ParameterKey=RepoName,ParameterValue=${RepoName} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
