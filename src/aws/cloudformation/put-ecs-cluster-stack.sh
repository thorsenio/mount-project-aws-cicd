#!/usr/bin/env bash

# This script creates a CloudFormation stack. It automatically expands nested templates.
# It will fail if the stack already exists.

# Constants
CLOUDFORMATION_TEMPLATE='templates/ecs-cluster.yml'

# Parse arguments
## Initialize arguments
WAIT=false

## Parse arguments
while :; do
  case $1 in
    # Handle known options
    --wait) WAIT=true ;;

    # End of known options
    --) shift ; break ;;

    # Handle unknown options
    -?*) printf 'WARNING: Unknown option (ignored): %s\n' "$1" 1>&2 ;;

    # No more options
    *) break
  esac
  shift
done


# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

STACK_NAME=${EcsClusterStackName}

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${STACK_NAME})

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

AZ_COUNT=$(echoCountAzsInRegion ${Profile} ${Region})
MAX_AZ_COUNT=3
DESIRED_AZ_COUNT=$(echoMin AZ_COUNT MAX_AZ_COUNT)

# TODO: MAYBE: Allow these values to be customized
if [[ ${BranchName} == 'master' ]]; then
  DESIRED_ASG_CAPACITY=2
else
  DESIRED_ASG_CAPACITY=1
fi

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${STACK_NAME} \
  --template-body file://${TEMPLATE_BASENAME}--expanded.yml \
  --parameters \
    ParameterKey=DefaultSecurityGroupName,ParameterValue=${VpcDefaultSecurityGroupName} \
    ParameterKey=DesiredAsgCapacity,ParameterValue=${DESIRED_ASG_CAPACITY} \
    ParameterKey=DesiredAzCount,ParameterValue=${DESIRED_AZ_COUNT} \
    ParameterKey=Ec2InstanceName,ParameterValue=${Ec2InstanceName} \
    ParameterKey=Ec2InstanceType,ParameterValue=${Ec2InstanceType} \
    ParameterKey=EcsClusterName,ParameterValue=${EcsClusterName} \
    ParameterKey=FileSystemName,ParameterValue=${FileSystemName} \
    ParameterKey=KeyPairKeyName,ParameterValue=${KeyPairKeyName} \
    ParameterKey=PlatformCommitHash,ParameterValue=${PlatformCommitHash} \
    ParameterKey=PlatformId,ParameterValue=${PlatformId} \
    ParameterKey=PlatformVersionLabel,ParameterValue=${PlatformVersionLabel} \
    ParameterKey=ProjectCommitHash,ParameterValue=${ProjectCommitHash} \
    ParameterKey=ProjectVersionLabel,ParameterValue=${ProjectVersionLabel} \
    ParameterKey=SiteDomainName,ParameterValue=${SiteDomainName} \
    ParameterKey=VpcName,ParameterValue=${EcsClusterVpcName} \
  --capabilities \
    CAPABILITY_AUTO_EXPAND \
    CAPABILITY_IAM \
)

echoPutStackOutput ${STACK_NAME} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?

if [[ ${WAIT} == true ]]; then
  aws cloudformation wait stack-${PUT_MODE}-complete \
    --profile ${Profile} \
    --region ${Region} \
    --stack-name ${STACK_NAME}
fi
