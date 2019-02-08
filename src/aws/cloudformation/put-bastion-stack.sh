#!/usr/bin/env bash

# This script creates a bastion host in a public subnet of the VPC that hosts container instances
# of the ECS cluster.

CLOUDFORMATION_TEMPLATE='templates/bastion-stack.yml'

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${BastionStackName})

# Return the ARN of the first container instance found in the cluster
getContainerInstanceArn () {
  echo $(
    aws ecs \
      list-container-instances \
      --profile ${PROFILE} \
      --region ${Region} \
      --cluster ${EcsClusterName} \
    ) | jq '.containerInstanceArns[0]'
}

# Given a container instance ID, return the value of one of that instance's attributes
getInstanceAttribute () {
  local CONTAINER_INSTANCE_ID=$1
  local KEY=$2

  echo $(
    aws ecs describe-container-instances \
      --cluster ${EcsClusterName} \
      --profile ${PROFILE} \
      --region ${Region} \
      --container-instances ${CONTAINER_INSTANCE_ID} \
    ) | jq ".containerInstances[0].attributes | .[] | select(.name==\"${KEY}\").value" | sed 's/\"//g'
}

# Given a container instance ID, return the ID of its first security group
getSecurityGroupId () {
  echo $(aws ec2 describe-security-groups \
    --profile ${PROFILE} \
    --region ${Region} \
    --filters Name=group-name,Values=${VpcDefaultSecurityGroupName} \
  ) | jq '.SecurityGroups[0].GroupId' | cut -d\" -f 2
}

# Given a VPC ID, return the ID of its first public subnet
getPrivateSubnetId () {
  local VPC_ID=${1}
  echo $(aws ec2 describe-subnets \
    --profile ${PROFILE} \
    --region ${Region} \
    --filters \
      Name=tag:Access,Values=public \
      Name=vpc-id,Values=${VPC_ID} \
  ) | jq '.Subnets[0].SubnetId' | cut -d\" -f 2
}

CONTAINER_INSTANCE_ARN=$(getContainerInstanceArn)

if [[ ${CONTAINER_INSTANCE_ARN} == 'null' ]]
then
  echo 'No container instances were found.' 1>&2
  exit 1
else
  echo "Container instance ARN: ${CONTAINER_INSTANCE_ARN}"
fi

CONTAINER_INSTANCE_ID=$(echo ${CONTAINER_INSTANCE_ARN} | cut -d\" -f 2 | awk -F'/' '{ print $NF }')

# TODO: Get the security group ID
SECURITY_GROUP_ID=$(getSecurityGroupId)

if [[ '' == ${SECURITY_GROUP_ID} ]]
then
  echo 'The security group ID could not be determined.' 1>&2
  exit 1
else
  echo "Security group ID: ${SECURITY_GROUP_ID}"
fi

VPC_ID=$(getInstanceAttribute ${CONTAINER_INSTANCE_ID} 'ecs.vpc-id')

if [[ '' == ${VPC_ID} ]]
then
  echo 'The VPC ID could not be determined.' 1>&2
  exit 1
else
  echo "VPC ID: ${VPC_ID}"
fi

SUBNET_ID=$(getPrivateSubnetId ${VPC_ID})

if [[ '' == ${SUBNET_ID} ]]
then
  echo 'The subnet ID could not be determined.' >&2
  exit 1
else
  echo "Subnet ID: ${SUBNET_ID}"
fi

OUTPUT=$(aws cloudformation create-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${BastionStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=KeyPairKeyName,ParameterValue=${KeyPairKeyName} \
    ParameterKey=ProjectName,ParameterValue=${ProjectName} \
    ParameterKey=SecurityGroupId,ParameterValue=${SECURITY_GROUP_ID} \
    ParameterKey=SubnetId,ParameterValue=${SUBNET_ID} \
    ParameterKey=VpcId,ParameterValue=${VPC_ID} \
  --capabilities CAPABILITY_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
