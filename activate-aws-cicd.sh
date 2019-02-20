#!/usr/bin/env bash

# This script opens a shell in which the AWS CLI and the AWS ECS CLI are enabled for management
# of the CI/CD pipeline

# Container code is copied into the container at /var/lib
# The current directory is mounted into the container at /var/project

BASE_NAME='skypilot/aws-cicd'

# TODO: Allow custom path(s) to the variables files

if [[ $# -gt 1 ]]
then
  echo "Usage: ${0} [tag]" 1>&2
  exit 1
fi

if [[ $# -eq 1 ]]
then
  TAG=$1
else
  TAG='latest'
fi

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

# Read environment variables
if [[ -f '.env' ]]
then
  source .env
fi
PROJECT_DIR=${PROJECT_DIR:='/var/project'}

# TODO: Allow different sources to be specified for `.aws`, `.ecs`, .ssh`

mkdir -p config

# TODO: Update the target directories when `USER` is set to something other than `root`
docker container run \
  --interactive \
  --rm \
  --tty \
  --mount type=bind,source=${PWD},target=${PROJECT_DIR} \
  --mount type=bind,source=${PWD}/config,target=/var/lib/config \
  --mount type=bind,source="${HOME}/.aws",target=/root/.aws \
  --mount type=bind,source="${HOME}/.ecs",target=/root/.ecs \
  --mount type=bind,source="${HOME}/.ssh",target=/root/.ssh \
  ${BASE_NAME}:${TAG} \
  bash
