#!/usr/bin/env bash

# This script builds the Docker image and tags it with the version information
# contained in `platform-variables.sh` and derived from the current Git branch name

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")
source platform-variables.sh

if [[ $? -ne 0 ]]
then
  echo "The variables file, 'platform-variables.sh', was not found" 1>&2
  exit 1
fi

embold () {
  local bold=$(tput bold)
  local normal=$(tput sgr0)

  local TextToEmbold=$1
  echo "${bold}${TextToEmbold}${normal}"
}

if [[ -z ${ACCOUNT_NAME} || -z ${PACKAGE_NAME} || -z ${VERSION} ]]
then
  echo "platform-variables.sh must define ACCOUNT_NAME, PACKAGE_NAME, and VERSION" 1>&2
  exit 1
fi

IMAGE_NAME="${ACCOUNT_NAME}/${PACKAGE_NAME}"

echo "Version stage: ${VERSION_STAGE}"

# If version stage is undefined, use the current Git branch
if [[ -z ${VERSION_STAGE} ]]; then
  BRANCH=$(git symbolic-ref --short HEAD)
  VERSION_STAGE=${BRANCH//\//-}
fi

# Build the tag: version number + version stage
# Omit the version stage if this is the master version
if [[ ${VERSION_STAGE} == 'master' ]]; then
  LABEL='latest'
  VERSION_LABEL=${VERSION}
else
  LABEL=${VERSION_STAGE}
  VERSION_LABEL=${VERSION}-${VERSION_STAGE}
fi

# Tag the build
docker build -t ${IMAGE_NAME}:${LABEL} . \
  --build-arg PACKAGE_NAME=${PACKAGE_NAME} \
  --build-arg VERSION=${VERSION} \
  --build-arg VERSION_STAGE=${VERSION_STAGE}

if [[ $? -ne 0 ]]
then
  exit 1
fi

# Also tag the image with the version number, prefixed by the custom tag (if any)
docker tag ${IMAGE_NAME}:${LABEL} ${IMAGE_NAME}:${VERSION_LABEL}
if [[ $? -ne 0 ]]; then
  exit 1
fi
echo "Successfully tagged ${IMAGE_NAME}:${VERSION_LABEL}"
