#!/usr/bin/env bash

# This script uses CloudFormation to create a VPC for the project's ECS stack.

CLOUDFORMATION_TEMPLATE='templates/vpc.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${VpcStackName})

./package.sh ${CLOUDFORMATION_TEMPLATE}

if [[ $? -ne 0 ]]
then
  exit 1
fi

AZ_COUNT=$(echoCountAzsInRegion ${PROFILE} ${Region})
MAX_AZ_COUNT=3
DESIRED_AZ_COUNT=$(echoMin AZ_COUNT MAX_AZ_COUNT)

OUTPUT=$(aws cloudformation create-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${VpcStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=DefaultSecurityGroupName,ParameterValue=${VpcDefaultSecurityGroupName} \
    ParameterKey=DesiredAzCount,ParameterValue=${DESIRED_AZ_COUNT} \
    ParameterKey=VpcName,ParameterValue=${VpcName} \
  --capabilities CAPABILITY_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
