#!/usr/bin/env bash

# This script empties the project's ECR repositories

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

for REPO_NAME in ${EcrRepoNames}; do
  FULL_REPO_NAME="${DeploymentId}/${REPO_NAME}"
  ./empty-ecr-repository.sh ${PROFILE} ${Region} ${FULL_REPO_NAME}
  if [[ $? -ne 0 ]]; then
    exit $?
  fi
done
