#!/usr/bin/env bash

# This script opens a shell in which the AWS CLI and the AWS ECS CLI are enabled for management
# of the CI/CD pipeline

# Container code is copied into the container at /var/lib
# The current directory is mounted into the container at /var/project

PACKAGE_NAME='mount-project-aws-cicd'

# TODO: FEATURE: Allow custom path(s) to the variables files
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


# -- End of helper functions

if [[ $# -gt 1 ]]
then
  echo "Usage: $0 [IMAGE_TAG]" 1>&2
  exit 1
fi

if [[ $# -eq 1 ]]
then
  TAG=$1
else
  TAG='latest'
fi

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")
IMAGE_BASE_NAME=${ACCOUNT_NAME}/${PACKAGE_NAME}

# Read environment variables
if [[ -f '.env' ]]
then
  source .env
fi
PROJECT_DIR=${PROJECT_DIR:='/var/project'}

# TODO: Allow different sources to be specified for `.aws`, `.ecs`, .ssh`

mkdir -p config \
  "${HOME}/.aws" \
  "${HOME}/.ecs" \
  "${HOME}/.ssh"

# TODO: Update the target directories when `USER` is set to something other than `root`
docker container run \
  --interactive \
  --rm \
  --tty \
  --env BRANCH=$(git symbolic-ref --short HEAD) \
  --env COMMIT_HASH=$(git rev-parse HEAD) \
  --mount type=bind,source=${PWD},target=${PROJECT_DIR} \
  --mount type=bind,source=${PWD}/config,target=/var/lib/config \
  --mount type=bind,source="${HOME}/.aws",target=/root/.aws \
  --mount type=bind,source="${HOME}/.ecs",target=/root/.ecs \
  --mount type=bind,source="${HOME}/.ssh",target=/root/.ssh \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  ${BASE_NAME}:${TAG} \
  bash

