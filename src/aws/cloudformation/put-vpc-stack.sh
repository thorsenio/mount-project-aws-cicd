#!/usr/bin/env bash

# This script uses CloudFormation to create a VPC for the project's ECS stack.

CLOUDFORMATION_TEMPLATE='templates/vpc-stack.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${EcsClusterStackName})

./package.sh ${CLOUDFORMATION_TEMPLATE}

if [[ $? -ne 0 ]]
then
  exit 1
fi

OUTPUT=$(aws cloudformation create-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${VpcStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=DefaultSecurityGroupName,ParameterValue=${VpcDefaultSecurityGroupName} \
    ParameterKey=StackName,ParameterValue=${EcsClusterStackName} \
  --capabilities CAPABILITY_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
