#!/usr/bin/env bash

DELETE_IDENTITIFY_FILE=${1:-''}
if [[ $1 == '--delete' ]]; then
  DELETE_KEY_PAIR_PARAM='--delete-identify-file'
else
  DELETE_KEY_PAIR_PARAM='--no-delete-identity-file'
fi

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../compute-variables.sh

STACK_NAME=${EcsClusterStackName}

# Check whether services are running in the cluster
SERVICE_COUNT=$(aws ecs list-services \
  --profile ${Profile} \
  --region ${Region} \
  --cluster ${EcsClusterName} \
  --query 'serviceArns[*] | length(@)' \
  > /dev/null \
)
if [[ $? -eq 0 && ${SERVICE_COUNT} -ne 0 ]]; then
  echo -e "The stack cannot be deleted, because ${SERVICE_COUNT} services are running in the cluster.\nAborting." 1>&2
  exit 1
fi


helpers/delete-stack.sh ${STACK_NAME} "$@"
exitOnError $?

../ec2/delete-key-pair.sh ${Profile} ${Region} ${KeyPairKeyName} ${DELETE_KEY_PAIR_PARAM}
