#!/usr/bin/env bash

# This script builds the Docker image and tags it with the version information
# contained in `platform-variables.sh`

# Handle arguments
if [[ $# -gt 1 ]]
then
  SHOW_USAGE='true'
fi

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

if [[ ${SHOW_USAGE} == 'true' ]]
then
  echo "Usage: ${0} [LABEL]"
  echo "Examples:"
  echo $(embold "  $0")
  echo "  tags the image with these tags: $(embold "${IMAGE_NAME}:latest"), $(embold "${IMAGE_NAME}:${VERSION}")"
  echo
  echo $(embold "  $0 edge")
  echo "  tags the image with these tags: $(embold "${IMAGE_NAME}:edge"), $(embold "${IMAGE_NAME}:edge-${VERSION}")"
  exit 1
fi

# Build the tag: label + version number
if [[ $# -eq 1 ]]
then
  LABEL=$1
  VERSION_PREFIX="${LABEL}-"
  VERSION_STAGE=${LABEL}
else
  LABEL='latest'
  VERSION_PREFIX=''
  VERSION_STAGE=''
fi

TAG="${VERSION_PREFIX}${VERSION}"


echo "Label: ${LABEL}"
echo "Tag: ${TAG}"

# Tag the build
docker build -t ${IMAGE_NAME}:${LABEL} . \
  --build-arg VERSION=${VERSION} \
  --build-arg VERSION_STAGE=${VERSION_STAGE} \
  --build-arg PACKAGE_NAME=${PACKAGE_NAME}

if [[ ${?} -ne 0 ]]
then
  exit 1
fi

# Also tag the image with the version number, prefixed by the custom tag (if any)
docker tag ${IMAGE_NAME}:${LABEL} ${IMAGE_NAME}:${TAG}
