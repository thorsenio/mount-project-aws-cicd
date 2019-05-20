#!/usr/bin/env bash

# This script builds the Docker image and tags it with the version information
# contained in `variables.sh` and derived from the current Git branch name

if [[ ! $1 == '--force' ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo -e "Please commit or stash your changes before building or use --force.\nAborting build" 1>&2
    exit 1
  fi
fi


# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")
source variables.sh

if [[ $? -ne 0 ]]
then
  echo "The variables file, 'variables.sh', was not found" 1>&2
  exit 1
fi

if [[ -z ${ACCOUNT_NAME} || -z ${PACKAGE_NAME} || -z ${VERSION} ]]
then
  echo "variables.sh must define ACCOUNT_NAME, PACKAGE_NAME, and VERSION" 1>&2
  exit 1
fi

IMAGE_NAME="${ACCOUNT_NAME}/${PACKAGE_NAME}"

# By default use the current branch name as the version stage (remove / and -)
if [[ -z ${VERSION_STAGE} ]]; then
  BRANCH=$(git symbolic-ref --short HEAD)
  VERSION_STAGE=${BRANCH//\//}
  VERSION_STAGE=${VERSION_STAGE//-/}
fi
COMMIT_HASH=$(git rev-parse HEAD)

# TODO: REFACTOR: Reduce duplication of code with `docker/build-images.sh`
# Build the version label: version number + version stage
# Omit the version stage if this is the master version
if [[ ${VERSION_STAGE} == 'master' ]]; then
  LABEL='latest'
  VERSION_LABEL="v${VERSION}"
else
  LABEL=${VERSION_STAGE}
  VERSION_LABEL="v${VERSION}-${VERSION_STAGE}"
fi

# Tag the build
docker build -t ${IMAGE_NAME}:${LABEL} . \
  --build-arg COMMIT_HASH=${COMMIT_HASH} \
  --build-arg PACKAGE_NAME=${PACKAGE_NAME} \
  --build-arg VERSION=${VERSION} \
  --build-arg VERSION_LABEL=${VERSION_LABEL} \
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
