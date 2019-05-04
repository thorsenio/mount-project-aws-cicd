#!/usr/bin/env bash

# This script uses CloudFormation to create a VPC for the project's ECS stack.

CLOUDFORMATION_TEMPLATE='templates/vpc.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
source ../aws-functions.sh
source ../../compute-variables.sh

STACK_NAME=${VpcStackName}

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${STACK_NAME})

./package.sh ${CLOUDFORMATION_TEMPLATE}

if [[ $? -ne 0 ]]
then
  exit 1
fi

AZ_COUNT=$(echoCountAzsInRegion ${Profile} ${Region})
MAX_AZ_COUNT=3
DESIRED_AZ_COUNT=$(echoMin AZ_COUNT MAX_AZ_COUNT)

OUTPUT=$(aws cloudformation create-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${STACK_NAME} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=DefaultSecurityGroupName,ParameterValue=${VpcDefaultSecurityGroupName} \
    ParameterKey=DesiredAzCount,ParameterValue=${DESIRED_AZ_COUNT} \
    ParameterKey=VpcName,ParameterValue=${VpcName} \
  --capabilities CAPABILITY_IAM \
)

echoPutStackOutput ${STACK_NAME} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?
