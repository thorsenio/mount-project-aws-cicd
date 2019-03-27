#!/usr/bin/env bash

# This script creates a CloudFormation stack. It automatically expands nested templates.
# It will fail if the stack already exists.

CLOUDFORMATION_TEMPLATE='templates/ecs-cluster.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
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

AZ_COUNT=$(echoCountAzsInRegion ${PROFILE} ${Region})
MAX_AZ_COUNT=3
DESIRED_AZ_COUNT=$(echoMin AZ_COUNT MAX_AZ_COUNT)

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${EcsClusterStackName} \
  --template-body file://${TEMPLATE_BASENAME}--expanded.yml \
  --parameters \
    ParameterKey=DefaultSecurityGroupName,ParameterValue=${VpcDefaultSecurityGroupName} \
    ParameterKey=DesiredAzCount,ParameterValue=${DESIRED_AZ_COUNT} \
    ParameterKey=Ec2InstanceName,ParameterValue=${Ec2InstanceName} \
    ParameterKey=Ec2InstanceType,ParameterValue=${Ec2InstanceType} \
    ParameterKey=EcsClusterName,ParameterValue=${EcsClusterName} \
    ParameterKey=FileSystemName,ParameterValue=${FileSystemName} \
    ParameterKey=KeyPairKeyName,ParameterValue=${KeyPairKeyName} \
    ParameterKey=PlatformCommitHash,ParameterValue=${PlatformCommitHash} \
    ParameterKey=PlatformId,ParameterValue=${PlatformId} \
    ParameterKey=PlatformVersionLabel,ParameterValue=${PlatformVersionLabel} \
    ParameterKey=VpcName,ParameterValue=${EcsClusterVpcName} \
  --capabilities \
    CAPABILITY_AUTO_EXPAND \
    CAPABILITY_IAM \
)

echoPutStackOutput ${EcsClusterStackName} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?
