#!/usr/bin/env bash

# This script opens a shell in which the AWS CLI and the AWS ECS CLI are enabled for management
# of the CI/CD pipeline

# Container code is copied into the container at /root/lib
# The current directory is mounted into the container at /root/project

# TODO: Allow custom path(s) to the variables files

if [[ ${#} -gt 1 ]]
then
  echo "Usage: ${0} [tag]" 1>&2
  exit 1
fi

if [[ ${#} -eq 1 ]]
then
  TAG=${1}
else
  TAG='latest'
fi

# Change to the directory of this script
cd $(dirname "$0")

mkdir -p config

docker container run \
  --interactive \
  --rm \
  --tty \
  --mount type=bind,source=${PWD},target=/root/project \
  --mount type=bind,source=${PWD}/config,target=/root/lib/config \
  --mount type=bind,source="${HOME}/.aws",target=/root/.aws \
  --mount type=bind,source="${HOME}/.ecs",target=/root/.ecs \
  --mount type=bind,source="${HOME}/.ssh",target=/root/.ssh \
  skypilot/ecs-stack:${TAG} \
  bash
