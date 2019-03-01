#!/usr/bin/env bash

# This script builds and tags the project's Docker images

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws/aws-functions.sh
source ../compute-variables.sh

# PROJECT_DIR is set when the aws-cicd image is built. See `build.sh`
# TODO: Allow this to be overridden
PROJECT_DIR=${PROJECT_DIR:-'/var/project'}
cd "${PROJECT_DIR}"

echo "PROJECT_DIR: ${PROJECT_DIR}"

# TODO: REFACTOR: Reduce duplication of code with `aws/ecr/push-images.sh`
# Build the tag: label + version number
if [[ ${BranchName} == 'master' ]]
then
  TAG=${ProjectVersion}
else
  TAG="${DeploymentName}-${ProjectVersion}"
fi

for IMAGE_NAME in ${EcrRepoNames}; do

  SHORT_TAG=${DeploymentId}/${IMAGE_NAME}:${TAG}
  LONG_TAG=${AccountNumber}.dkr.ecr.${Region}.amazonaws.com/${SHORT_TAG}

  DOCKERFILE=${IMAGE_NAME}.Dockerfile
  DOCKERFILE_PATH=${PROJECT_DIR}/${DOCKERFILE}

  if [[ ! -f "${DOCKERFILE_PATH}" ]]; then
    echo "The build could not proceed. ${DOCKERFILE_PATH} WAS NOT FOUND" 1>&2
    exit 1
  fi

  echo "Building ${SHORT_TAG}"

  docker build \
    --file ${DOCKERFILE_PATH} \
    --tag ${LONG_TAG} \
    ${PROJECT_DIR}

  if [[ $? -ne 0 ]]; then
    echo "Docker failed to build ${SHORT_TAG}" 1>&2
    exit 1
  fi

done