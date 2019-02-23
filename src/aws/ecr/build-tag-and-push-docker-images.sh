#!/usr/bin/env bash

# This script builds and tags the project's Docker images, authenticates Docker to AWS, and then
# pushes the images to ECR.

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

AUTH_OUTPUT=$(aws ecr get-login \
  --no-include-email \
  --profile ${PROFILE} \
  --region ${Region} \
)

if [[ $? -ne 0 ]]
then
  echo ${AUTH_OUTPUT}
  "Docker could not authenticate to AWS ECR" 1>&2
  exit 1
fi

# Build the tag: label + version number
if [[ ${BranchName} == 'master' ]]
then
  TAG=${ProjectVersion}
else
  TAG="${DeploymentName}-${ProjectVersion}"
fi

for IMAGE_NAME in ${EcrRepoNames}; do
  # Create the repo if it doesn't exist

  ./put-repository.sh ${IMAGE_NAME}

  SHORT_TAG=${IMAGE_NAME}:${TAG}
  LONG_TAG=${AccountNumber}.dkr.ecr.${Region}.amazonaws.com/${DeploymentId}/${SHORT_TAG}

  continue

  docker build \
    --file ${IMAGE_NAME}.Dockerfile \
    --tag ${LONG_TAG} \
    ../..
  if [[ $? -ne 0 ]]; then
    echo "Docker failed to build "
    exit 1
  fi

  docker push ${LONG_TAG}

  if [[ $? -ne 0 ]]
  then
    "The '${SHORT_TAG}' image could not be uploaded to ECR" 1>&2
    exit 1
  fi
done
