#!/usr/bin/env bash

# This script opens a shell in which the AWS CLI and the AWS ECS CLI are enabled for management
# of the CI/CD pipeline

# Container code is copied into the container at the location set in `PROJECT_LIB` (default: `/var/lib`)
# The current directory is mounted into the container at the location set in `PROJECT_DIR` (default: `/var/project`)

# TODO: FEATURE: Allow custom path(s) to the project's config files
# TODO: REFACTOR: Don't allow stack to be launched when the working tree is dirty

# -- Helper functions
# Given a relative path to a file, echo its absolute path.
# macOS doesn't have `realpath`, so we do it the hard way here.
# Source: https://stackoverflow.com/questions/4175264/
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
  echo "Usage: $0 [VERSION_STAGE]" 1>&2
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


# Store values in unique variables, to avoid potential collisions
# Note: This script assumes that the package name is the same as the Docker repo name.
MPAC_DEBUG=${DEBUG:=false}
MPAC_PACKAGE_NAME=${PACKAGE_NAME}
MPAC_PROJECT_DIR=${PROJECT_DIR:='/var/project'}
MPAC_VERSION=${VERSION}
IMAGE_BASE_NAME=${DOCKER_ACCOUNT_NAME}/${MPAC_PACKAGE_NAME}
# -- End of read package variables


# Handle arguments
if [[ $# -gt 1 ]]; then
  showHelp
  exit 1
fi

if [[ $1 == '--help' || $1 == '-h'  || $1 == '-\?' ]]; then
  showHelp
  exit 0
fi

# -- Read project variables
# Change to the project's root directory before getting the Git branch name & reading `.env`
cd "${MPAC_PROJECT_ROOT}"


if [[ $# -eq 1 ]]; then
  DEFAULT_VERSION_STAGE=$(branchNameToVersionStage $1)
else
  BRANCH_NAME=$(getGitBranchName)
  DEFAULT_VERSION_STAGE=$(branchNameToVersionStage ${BRANCH_NAME})
fi

read -p "Version stage: [${DEFAULT_VERSION_STAGE}] " VERSION_STAGE
# TODO: Validate the entered text (should consist only of alphanumeric chars)
if [[ -z ${VERSION_STAGE} ]]; then
  VERSION_STAGE=${DEFAULT_VERSION_STAGE}
fi


# Read environment variables from the project's `.env` file, if any
if [[ -f '.env' ]]
then
  source .env
fi
# -- End of read project variables


if [[ ${MPAC_DEBUG} == true ]]; then
  echo "Project version stage: ${VERSION_STAGE}"
  echo "Project root: ${MPAC_PROJECT_ROOT}"
  echo "Relative path to script: ${SCRIPT_RELATIVE_PATH}"
  echo "Absolute path to script: ${SCRIPT_ABSOLUTE_PATH}"
  echo "Absolute dir of script: ${SCRIPT_ABSOLUTE_DIR}"
fi


# Create directories that will be mounted into the container, if they don't already exist
# TODO: Allow different sources to be specified for `.aws`, `.ecs`, .ssh`
mkdir -p config \
  "${HOME}/.aws" \
  "${HOME}/.ecs" \
  "${HOME}/.ssh"

# Pull the Docker image, unless it is already available locally
if ! dockerUseLocalImageOrPull ${IMAGE_BASE_NAME}:${MPAC_VERSION}; then
  exit 1
fi


# TODO: Update the target directories when `USER` is set to something other than `root`
# TODO: For clarity, the Docker image should be rewritten to expect `VERSION_STAGE` instead of `BRANCH`
docker container run \
  --interactive \
  --rm \
  --tty \
  --env COMMIT_HASH=$(getGitCommitHash) \
  --env VERSION_STAGE=${VERSION_STAGE} \
  --mount type=bind,source=${PWD},target=${MPAC_PROJECT_DIR} \
  --mount type=bind,source=${PWD}/config,target=/var/lib/config \
  --mount type=bind,source="${HOME}/.aws",target=/root/.aws \
  --mount type=bind,source="${HOME}/.ecs",target=/root/.ecs \
  --mount type=bind,source="${HOME}/.ssh",target=/root/.ssh \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  ${IMAGE_BASE_NAME}:${MPAC_VERSION} \
  bash
