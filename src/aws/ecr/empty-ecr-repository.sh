#!/usr/bin/env bash

# This script empties the specified ECR repository

if [[ $# -lt 3 || $# -gt 4 ]]
then
  echo "Usage: ${0} PROFILE REGION REPOSITORY_NAME [DESCRIPTION]" >&2
  exit 1
fi

# Required arguments
PROFILE=$1
REGION=$2
REPOSITORY_NAME=$3

# Optional argument
if [[ $# -eq 4 ]]
then
  DESCRIPTION="$4"
else
  DESCRIPTION=${REPOSITORY_NAME}
fi

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh

ecrRepoExists ${PROFILE} ${REGION} ${REPOSITORY_NAME}
if [[ $? -eq 0 ]]; then
  # The repo exists, so empty it
  echo "Emptying the '${DESCRIPTION}' ECR repository ..."

  IMAGE_TAGS=$(aws ecr list-images \
    --profile ${PROFILE} \
    --region ${REGION} \
    --repository-name ${REPOSITORY_NAME} \
    --query 'imageIds[*].imageTag' \
    --output text \
    | sed -e 's/\t/ /g' | tr -s ' '
  )
  if [[ $? -ne 0 ]]; then
    # The repository is empty
    echo "| The list of images could not be retrieved (Error $?)"
    exit 1
  fi

  if [[ ${#IMAGE_TAGS} -eq 0 ]]; then
    echo "| The repository is already empty."
  else
    # IMAGE_TAGS is not zero-length, so there are images to delete
    PREFIXED_IMAGE_TAGS=$(
      for IMAGE_TAG in ${IMAGE_TAGS}; do
        printf "imageTag=${IMAGE_TAG} "
      done
    )

    echo "| Deleting images: ${IMAGE_TAGS} ..."

    OUTPUT=$(aws ecr batch-delete-image \
      --profile ${PROFILE} \
      --region ${REGION} \
      --repository-name ${REPOSITORY_NAME} \
      --image-ids ${PREFIXED_IMAGE_TAGS} \
    )

    if [[ $? -eq 0 ]]; then
      echo "| The repository was emptied."
    else
      echo ${OUTPUT}
      echo "| The '${DESCRIPTION}' ECR repository could not be emptied."
      exit 1
    fi
  fi
fi
