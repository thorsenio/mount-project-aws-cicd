#!/usr/bin/env bash

# This script opens a shell in which the AWS CLI and the AWS ECS CLI are enabled for management
# of the CI/CD pipeline

# Container code is copied into the container at /var/lib
# The current directory is mounted into the container at /var/project

# TODO: FEATURE: Allow custom path(s) to the project's config files
# TODO: REFACTOR: Move as much code as possible into the platform code
# TODO: REFACTOR: Don't allow stack to be launched when the working tree is dirty

# -- Helper functions
# Given a relative path to a file, echo its absolute path.
# macOS doesn't have `realpath`, so we do it the hard way here.
# Source: https://stackoverflow.com/questions/4175264/bash-retrieve-absolute-path-given-relative/21951256#21951256
absolutePath () {
  local thePath
  if [[ ! "$1" =~ ^/ ]]; then
    thePath="$PWD/$1"
  else
    thePath="$1"
  fi

  echo "$thePath"|(
    IFS=/
    read -a parr
    declare -a outp
    for i in "${parr[@]}";do
      case "$i" in
      ''|.) continue ;;
      ..)
        len=${#outp[@]}
        if ((len == 0));then
          continue
        else
          unset outp[$((len-1))]
        fi
        ;;
      *)
        len=${#outp[@]}
        outp[$len]="$i"
        ;;
      esac
    done
    echo /"${outp[*]}"
  )
}


getProjectRoot () {
  # TODO: Use a more certain method of finding the project root. This method fails if the current
  #  project is not in a Git repo or if the project has submodules.
  echo $(git rev-parse --show-toplevel)
}


showHelp () {
  echo "Usage: $0 [PROJECT_VERSION_STAGE]" 1>&2
  echo "The version stage defaults to the branch name."
}
# -- End of helper functions


# -- Read package variables
# Store the project's root dir so that the project's `.env` file can be loaded
MPAC_PROJECT_ROOT=$(getProjectRoot)

# Find the real location of the current script
SCRIPT_RELATIVE_PATH="$0"
if [[ -h "${SCRIPT_RELATIVE_PATH}" ]]; then
  # The file is a symlink, so find its target. Change to the script's directory so that the
  # relative path is correctly resolved
  cd $(dirname "$0")
  SCRIPT_RELATIVE_PATH=$(readlink "$0")
  echo "Relative path to real script: ${SCRIPT_RELATIVE_PATH}"
fi

SCRIPT_ABSOLUTE_PATH=$(absolutePath ${SCRIPT_RELATIVE_PATH})
SCRIPT_ABSOLUTE_DIR=$(dirname ${SCRIPT_ABSOLUTE_PATH})
cd "${SCRIPT_ABSOLUTE_DIR}"


# Read this module's environment variables from file.
source ../variables.sh
if [[ $? -ne 0 ]]; then
  echo -e "The variables file for could not be found. Aborting."
  exit 1
fi

# Validate variables
if [[ -z ${DOCKER_ACCOUNT_NAME} || -z ${PACKAGE_NAME} || -z ${VERSION} ]]
then
  echo "variables.sh must define ACCOUNT_NAME, PACKAGE_NAME, and VERSION" 1>&2
  exit 1
fi


# Include helper functions.
source ../src/functions.sh
if [[ $? -ne 0 ]]; then
  echo -e "The functions file could not be found. Aborting."
  exit 1
fi


# Handle arguments
if [[ $# -gt 1 ]]; then
  showHelp
  exit 1
fi

if [[ $1 == '--help' || $1 == '-h'  || $1 == '-\?' ]]; then
  showHelp
  exit 1
fi

if [[ $# -eq 1 ]]; then
  VERSION_STAGE=$(branchNameToVersionStage $1)
else
  BRANCH_NAME=$(getGitBranchName)
  VERSION_STAGE=$(branchNameToVersionStage ${BRANCH_NAME})
fi


# TODO: Remove this debugging info
echo "Version stage: ${VERSION_STAGE}"
echo "Project root: ${MPAC_PROJECT_ROOT}"
echo "Relative path to script: ${SCRIPT_RELATIVE_PATH}"
echo "Absolute path to script: ${SCRIPT_ABSOLUTE_PATH}"
echo "Absolute dir of script: ${SCRIPT_ABSOLUTE_DIR}"


# Store values in unique variables, to avoid potential collisions
# Note: This script assumes that the package name is the same as the Docker repo name.
MPAC_PACKAGE_NAME=${PACKAGE_NAME}
MPAC_PROJECT_DIR=${PROJECT_DIR:='/var/project'}
MPAC_VERSION=${VERSION}
IMAGE_BASE_NAME=${DOCKER_ACCOUNT_NAME}/${MPAC_PACKAGE_NAME}
# -- End of read package variables


# -- Read project variables
# Change to the project's root directory
cd "${MPAC_PROJECT_ROOT}"


# Read environment variables from the project's `.env` file, if any
if [[ -f '.env' ]]
then
  source .env
fi
# -- End of read project variables


# Create directories that will be mounted into the container, if they don't already exist
# TODO: Allow different sources to be specified for `.aws`, `.ecs`, .ssh`
mkdir -p config \
  "${HOME}/.aws" \
  "${HOME}/.ecs" \
  "${HOME}/.ssh"

if ! dockerUseLocalImageOrPull ${IMAGE_BASE_NAME}:${MPAC_VERSION}; then
  exit 1
fi


# TODO: Update the target directories when `USER` is set to something other than `root`
# TODO: The Docker image should expect `VERSION_STAGE` instead of `BRANCH_NAME`
docker container run \
  --interactive \
  --rm \
  --tty \
  --env BRANCH_NAME=${VERSION_STAGE} \
  --env COMMIT_HASH=$(getGitCommitHash) \
  --mount type=bind,source=${PWD},target=${MPAC_PROJECT_DIR} \
  --mount type=bind,source=${PWD}/config,target=/var/lib/config \
  --mount type=bind,source="${HOME}/.aws",target=/root/.aws \
  --mount type=bind,source="${HOME}/.ecs",target=/root/.ecs \
  --mount type=bind,source="${HOME}/.ssh",target=/root/.ssh \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  ${IMAGE_BASE_NAME}:${MPAC_VERSION} \
  bash
