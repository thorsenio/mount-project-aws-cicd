#!/usr/bin/env bash

# This script creates the code pipeline stack, or updates it if it already exists

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

../codecommit/put-codecommit-repository.sh ${RepoName} "${RepoDescription}"

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d. -f1)

# -- Check prerequisites
if ! iamRoleExists ${PROFILE} ${Region} ${CodePipelineServiceRoleName}; then
  echo 'The code pipeline service role was not found' 1>&2
  echo "Fix this by creating the global platform stack ('${GlobalPlatformStackName}'):" 1>&2
  echo "  put-global-platform-stack.sh" 1>&2
  echo "  (NOTE: The Region must temporarily be set to 'us-west-1' in project-variable.sh.)"
  exit 1
fi

f ! bucketExists ${PROFILE} ${CicdArtifactsBucketName}; then
  echo 'The CI/CD artifacts bucket was not found' 1>&2
  echo "Fix this by creating the regional platform stack ('${RegionalPlatformStackName}'):" 1>&2
  echo "  put-regional-platform-stack.sh" 1>&2
  exit 1
fi

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${CodePipelineStackName} \
  --template-body file://${TEMPLATE_BASENAME}--expanded.yml \
  --parameters \
    ParameterKey=BranchName,ParameterValue=${BranchName} \
    ParameterKey=CicdArtifactsBucketName,ParameterValue=${CicdArtifactsBucketName} \
    ParameterKey=CodeBuildEnvironmentImage,ParameterValue=${CodeBuildEnvironmentImage} \
    ParameterKey=CodeBuildProjectName,ParameterValue=${CodeBuildProjectName} \
    ParameterKey=CodeBuildServiceRoleName,ParameterValue=${CodeBuildServiceRoleName} \
    ParameterKey=CodeBuildServiceRolePolicyName,ParameterValue=${CodeBuildServiceRolePolicyName} \
    ParameterKey=CodePipelineName,ParameterValue=${CodePipelineName} \
    ParameterKey=CodePipelineServiceRoleName,ParameterValue=${CodePipelineServiceRoleName} \
    ParameterKey=DeploymentId,ParameterValue=${DeploymentId} \
    ParameterKey=EventsRuleRandomId,ParameterValue=${EventsRuleRandomId} \
    ParameterKey=PlatformCommitHash,ParameterValue=${PlatformCommitHash} \
    ParameterKey=PlatformId,ParameterValue=${PlatformId} \
    ParameterKey=PlatformVersionLabel,ParameterValue=${PlatformVersionLabel} \
    ParameterKey=ProjectBucketName,ParameterValue=${ProjectBucketName} \
    ParameterKey=ProjectCommitHash,ParameterValue=${ProjectCommitHash} \
    ParameterKey=ProjectDescription,ParameterValue="${ProjectDescription}" \
    ParameterKey=ProjectName,ParameterValue=${ProjectName} \
    ParameterKey=ProjectVersionLabel,ParameterValue=${ProjectVersionLabel} \
    ParameterKey=RepoName,ParameterValue=${RepoName} \
  --capabilities \
    CAPABILITY_AUTO_EXPAND \
    CAPABILITY_IAM \
    CAPABILITY_NAMED_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
