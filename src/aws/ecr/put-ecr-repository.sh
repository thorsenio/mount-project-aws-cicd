#!/usr/bin/env bash

# This script creates the specified ECR repository if it doesn't already exist

if [[ $# -lt 1 ]]
then
  echo "Usage: $0 IMAGE_NAME" 1>&2
  exit 1
fi

IMAGE_NAME=$1

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

REPO_NAME=${DeploymentId}/${IMAGE_NAME}

if ecrRepoExists ${PROFILE} ${Region} ${REPO_NAME}; then
  echo "The '${REPO_NAME}' ECR repository exists and will be re-used."
  exit 0
fi

OUTPUT=$(
  aws ecr create-repository \
    --profile ${PROFILE} \
    --region ${Region} \
    --repository-name ${REPO_NAME} \
    --tags Key=DeploymentId,Value=${DeploymentId} \
)

if [[ $? -eq 0 ]]; then
  echo "The '${REPO_NAME}' ECR repository has been created."
else
  echo ${OUTPUT}
  echo "The '${REPO_NAME}' ECR repository could not be created."
  exit 1
fi
