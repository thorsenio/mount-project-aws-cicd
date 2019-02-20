#!/usr/bin/env bash

# This script creates a CloudFormation stack. It automatically expands nested templates.
# It will fail if the stack already exists.

CLOUDFORMATION_TEMPLATE='templates/ecs-cluster-stack.yml'

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

../ec2/create-key-pair.sh

if [[ $? -ne 0 ]]
then
  exit 1
fi

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d. -f1)

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${EcsClusterStackName} \
  --template-body file://${TEMPLATE_BASENAME}--expanded.yml \
  --parameters \
    ParameterKey=DefaultSecurityGroupName,ParameterValue=${VpcDefaultSecurityGroupName} \
    ParameterKey=EcsClusterName,ParameterValue=${EcsClusterName} \
    ParameterKey=KeyPairKeyName,ParameterValue=${KeyPairKeyName} \
    ParameterKey=VpcName,ParameterValue=${EcsClusterVpcName} \
  --capabilities \
    CAPABILITY_AUTO_EXPAND \
    CAPABILITY_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
