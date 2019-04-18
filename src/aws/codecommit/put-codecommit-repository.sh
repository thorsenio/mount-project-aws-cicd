#!/usr/bin/env bash

# This script creates the specified CodeCommit repository if it doesn't already exist

if [[ $# -lt 1 ]]
then
  echo "Usage: $0 REPOSITORY_NAME [REPOSITORY_DESCRIPTION]" 1>&2
  exit 1
fi

REPO_NAME=$1
REPO_DESCRIPTION=${2:-''}

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

if codecommitRepoExists ${Profile} ${Region} ${REPO_NAME}; then
  echo "The '${REPO_NAME}' CodeCommit repository exists and will be re-used."
  exit 0
fi

OUTPUT=$(aws codecommit create-repository \
  --profile ${Profile} \
  --region ${Region} \
  --repository-name ${REPO_NAME} \
  --repository-description "${REPO_DESCRIPTION}"
)

if [[ $? -eq 0 ]]; then
  echo "The '${REPO_NAME}' CodeCommit repository has been created."
  cd "${PROJECT_DIR}"
  git remote add aws ssh://git-codecommit.${Region}.amazonaws.com/v1/repos/${REPO_NAME}
else
  echo "${OUTPUT}"
  echo "The '${REPO_NAME}' CodeCommit repository could not be created." 1>&2
  exit 1
fi
