#!/usr/bin/env bash

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

REPO_NAME=$(aws codecommit create-repository \
  --profile ${PROFILE} \
  --region ${Region} \
  --repository-name ${RepoName} \
  --repository-description "${RepoDescription}" \
  | jq '.repositoryMetadata.repositoryName' | cut -d\" -f 2
)

if [[ ${?} -ne 0 ]]
then
  exit 1
fi

echo "CodeCommit repository created: '${REPO_NAME}'"
