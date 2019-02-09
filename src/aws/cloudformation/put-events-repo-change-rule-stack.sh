#!/usr/bin/env bash

TEMPLATE_FILE='./events-repo-change-rule.yml'

# Change to the directory of this script
cd $(dirname "$0")

source functions.sh
source variables-computed.sh

CodePipelineArn="arn:aws:codepipeline:${Region}:${AccountNumber}:${CodePipelineName}"

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${CloudWatchRepoChangeRuleStackName})

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${CloudWatchRepoChangeRuleStackName} \
  --template-body file://${TEMPLATE_FILE} \
  --parameters \
    ParameterKey=CodePipelineArn,ParameterValue=${CodePipelineArn} \
    ParameterKey=CodePipelineName,ParameterValue=${CodePipelineName} \
    ParameterKey=ProjectName,ParameterValue=${ProjectName} \
    ParameterKey=RepoName,ParameterValue=${RepoName} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
