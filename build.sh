#!/usr/bin/env bash

# This script builds the Docker image and tags it with the version number found in `.version`

BASE_NAME='skypilot/ecs-stack'

if [[ ${#} -gt 1 ]]
then
  VERSION=$(head -n 1 .version) &> /dev/null
  VERSION="${VERSION:=1.0.0}"
  echo "Usage: ${0} [TAG_LABEL]"
  echo "Examples:"
  echo "  ${0}"
  echo "  tags the image with these tags: '${BASE_NAME}:latest', '${BASE_NAME}:${VERSION}'"
  echo
  echo "  ${0} 'edge'"
  echo "  tags the image with these tags: '${BASE_NAME}:edge', '${BASE_NAME}:edge-${VERSION}'"
  exit 1
fi

if [[ ${#} -eq 1 ]]
then
  TAG="${1}"
  VERSION_TAG_PREFIX="${TAG}-"
else
  TAG="latest"
  VERSION_TAG_PREFIX=""
fi

# Change to the directory of this script
cd $(dirname "$0")

VERSION_TAG="${VERSION_TAG_PREFIX}$(head -n 1 .version)"

if [[ ${?} -ne 0 ]]
then
  echo "The version number was not found" 1>&2
  exit 1
fi

echo "Tag: ${TAG}"
echo "Version tag: ${VERSION_TAG}"

# Tag the build with `latest` or the custom tag passed as an argument
docker build -t skypilot/ecs-stack:${TAG} .

if [[ ${?} -ne 0 ]]
then
  exit 1
fi

# Also tag the image with the version number, prefixed by the custom tag (if any)
docker tag skypilot/ecs-stack:${TAG} skypilot/ecs-stack:${VERSION_TAG}
