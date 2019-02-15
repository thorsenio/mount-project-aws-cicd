#!/usr/bin/env bash

# This script connects to the nth-index cluster instance of the ECS stack via a bastion host,
# either for an SSH login or for port forwarding.
#
# Example 1: To log in to the 1st container instance:
#
#   ```
#   connect-via-bastionto-ecs-instance.sh login 0
#   ```
#
# Example 2: To forward port 80 of the local host to port 80 of the 2nd container instance:
#
#   ```
#   connect-via-bastion-to-ecs-instance.sh forward 0 80
#   ```

if [[ ${#} -lt 1 ]]
then
  echo "Usage: ${0} login|forward INSTANCE_INDEX [PORT]" 1>&2
  exit 1
fi

if [[ ! ${1} == 'login' && ! ${1} == 'forward' ]]
then
  echo "Usage: ${0} login|forward INSTANCE_INDEX [PORT]" 1>&2
  exit 1
fi

ACTION=${1}
shift

if [[ ${ACTION} == 'login' ]]
then
  if [[ ${#} -lt 1 ]]
  then
    echo "Usage: ${0} login INSTANCE_INDEX" 1>&2
    exit 1
  fi
else
  if [[ ${#} -lt 2 ]]
  then
    echo "Usage: ${0} forward INSTANCE_INDEX PORT" 1>&2
    exit 1
  fi
  PORT=${2}
fi

INSTANCE_INDEX=${1}

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../aws-functions.sh
source ../../../compute-variables.sh

IDENTITY_FILE=~/.ssh/${KeyPairKeyName}.pem

# TODO: USABILITY: Test whether identity file exists

extractInstanceIdFromArn () {
  local INSTANCE_ARN=${1}
  echo ${INSTANCE_ARN} | cut -d/ -f 2
}

getEcsInstanceArnByIndex () {
  local INDEX=${1}
  echo $(aws ecs list-container-instances \
    --profile ${PROFILE} \
    --region ${Region} \
    --cluster ${EcsClusterName} \
  ) | jq ".containerInstanceArns[${INDEX}]" | cut -d\" -f 2
}

getContainerInstanceIdByArn () {
  local INSTANCE_ARN=${1}
  echo $(aws ecs describe-container-instances \
    --profile=${PROFILE} \
    --region=${Region} \
    --cluster ${EcsClusterName} \
    --container-instances ${INSTANCE_ARN} \
  ) | jq '.containerInstances[0].ec2InstanceId' | cut -d\" -f 2
}

getInstanceIdByName () {
  local INSTANCE_NAME=${1}
  echo $(aws ec2 describe-instances \
    --profile=${PROFILE} \
    --region=${Region} \
    --filters Name=tag:Name,Values=${INSTANCE_NAME} \
  ) | jq '.Reservations[0].Instances[0].InstanceId' | cut -d\" -f 2
}

getPrivateIpbyInstanceId () {
  local INSTANCE_ID=${1}
  echo $(aws ec2 describe-instances \
    --profile=${PROFILE} \
    --region=${Region} \
    --instance-ids ${INSTANCE_ID} \
  ) | jq '.Reservations[0].Instances[0].PrivateIpAddress' | cut -d\" -f 2
}

getPublicIpbyInstanceId () {
  local INSTANCE_ID=${1}
  echo $(aws ec2 describe-instances \
    --profile=${PROFILE} \
    --region=${Region} \
    --instance-ids ${INSTANCE_ID} \
  ) | jq '.Reservations[0].Instances[0].PublicIpAddress' | cut -d\" -f 2
}

BASTION_INSTANCE_ID=$(getInstanceIdByName ${BastionInstanceName})

if [[ ${BASTION_INSTANCE_ID} == 'null' ]]
then
  echo "The connection could not be made. Bastion host '${BastionInstanceName}' was not found." 1>&2
  exit 1
fi

ARN=$(getEcsInstanceArnByIndex ${INSTANCE_INDEX})

CONTAINER_INSTANCE_ID=$(getContainerInstanceIdByArn ${ARN})

CONTAINER_INSTANCE_IP=$(getPrivateIpbyInstanceId ${CONTAINER_INSTANCE_ID})

BASTION_IP=$(getPublicIpbyInstanceId ${BASTION_INSTANCE_ID})

if [[ ${BASTION_IP} == 'null' ]]
then
  echo "The connection could not be made. The bastion host was not found." 1>&2
  exit 1
fi

echo "Container instance IP: ${CONTAINER_INSTANCE_IP}"
echo "Bastion host IP: ${BASTION_IP}"

if [[ ${ACTION} == 'login' ]]
then
  ./ssh-via-bastion.sh ${CONTAINER_INSTANCE_IP} ${BASTION_IP} ${IDENTITY_FILE}
else # 'forward'
  ./forward-via-bastion.sh ${PORT} ${CONTAINER_INSTANCE_IP} ${BASTION_IP} ${IDENTITY_FILE}
fi

if [[ ${?} -eq 0 ]]
then
  exit 0
else
  exit 1
fi
