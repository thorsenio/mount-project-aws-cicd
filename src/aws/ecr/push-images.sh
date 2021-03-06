#!/usr/bin/env bash

# This script authenticates Docker to AWS & pushes the project's Docker images to ECR
# The images need to exist already, so run `src/docker/build-images.sh` first

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

$(aws ecr get-login \
  --no-include-email \
  --profile ${Profile} \
  --region ${Region} \
)

if [[ $? -ne 0 ]]
then
  "Docker could not authenticate to AWS ECR" 1>&2
  exit 1
fi

for IMAGE_NAME in ${EcrRepoNames}; do
  # Create the repo if it doesn't exist

  ./put-ecr-repository.sh ${IMAGE_NAME}

  # Note that `LABEL` isn't used
  SHORT_TAG=${DeploymentId}/${IMAGE_NAME}:${ProjectVersionLabel}
  LONG_TAG=${AccountNumber}.dkr.ecr.${Region}.amazonaws.com/${SHORT_TAG}

  docker push ${LONG_TAG}

  if [[ $? -ne 0 ]]
  then
    "The '${SHORT_TAG}' image could not be pushed to ECR" 1>&2
    exit 1
  fi
done
