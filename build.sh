#!/usr/bin/env bash

# This script builds the Docker image and tags it with the version information
# contained in `variables.sh` and derived from the current Git branch name

# TODO: Eliminate code duplication between `mount-project.sh` and this script

# -- Helper functions
showHelp () {
  echo "Usage: $0 [--force]"
}
# -- End of helper functions


# -- Handle options
# Initialize options
FORCE_DIRTY_BUILD=false

while :; do
  case $1 in
     -h|-\?|--help)
       showHelp ; exit ;;
     -F|--force)
       FORCE_DIRTY_BUILD=true ;;
     --) # End of all options
       shift ; break ;;
     -?*)
       printf 'WARNING: Unknown option (ignored): %s\n' "$1" >&2 ;;
     *)  # No more options, so break out of the loop
       break
   esac
   shift
 done


# Handle arguments
if [[ $# -ne 0 ]]; then
  showHelp
  exit 1
fi


# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

# Read this module's environment variables from file.
source variables.sh
if [[ $? -ne 0 ]]; then
  echo -e "The variables file could not be found. Aborting."
  exit 1
fi

# Validate variables
if [[ -z ${DOCKER_ACCOUNT_NAME} || -z ${PACKAGE_NAME} || -z ${VERSION} ]]
then
  echo "variables.sh must define ACCOUNT_NAME, PACKAGE_NAME, and VERSION" 1>&2
  exit 1
fi

# Include helper functions.
source src/functions.sh
if [[ $? -ne 0 ]]; then
  echo -e "The functions file could not be found. Aborting."
  exit 1
fi

if gitRepoIsClean; then
  COMMIT_HASH=$(getGitCommitHash)
else
  if [[ ${FORCE_DIRTY_BUILD} == true ]]; then
    echo "WARNING: There are uncommitted changes in the working tree. The commit hash will be set to 'unknown'."
    COMMIT_HASH='unknown'
  else
    echo -e "Please commit or stash your changes before building or use the \`--force\` option.\nThe build has been aborted." 1>&2
    exit 1
  fi
fi


IMAGE_BASE_NAME="${DOCKER_ACCOUNT_NAME}/${PACKAGE_NAME}"
VERSION_LABEL=$(generateVersionLabel ${VERSION} ${VERSION_STAGE})
IMAGE_BASE_NAME=${DOCKER_ACCOUNT_NAME}/${PACKAGE_NAME}

# TODO: REFACTOR: Reduce duplication of code with `docker/build-images.sh`
# TODO: REFACTOR: Versioning

# Tag the build
docker build \
  --tag ${IMAGE_BASE_NAME}:${VERSION_LABEL} \
  . \
  --build-arg COMMIT_HASH=${COMMIT_HASH} \
  --build-arg PACKAGE_NAME=${PACKAGE_NAME} \
  --build-arg PLATFORM_NAME=${PLATFORM_NAME} \
  --build-arg VERSION=${VERSION} \
  --build-arg VERSION_LABEL=${VERSION_LABEL} \
  --build-arg VERSION_STAGE=${VERSION_STAGE}

if [[ $? -ne 0 ]]
then
  exit 1
fi
