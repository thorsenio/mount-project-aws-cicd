#!/usr/bin/env bash

# Change to the directory of this script
cd $(dirname "${0}")

source ../aws-functions.sh
source ../../compute-variables.sh

# TODO: Refactor the special handling of us-east-1.
#   If `LocationConstraint` is specified for that region, the operation fails with an
#   InvalidLocationConstraint error.
#   Can share code with `create-cf-templates-bucket.sh`

# Skip creation of the bucket if it already exists
bucketExists ${PROFILE} ${CodeBuildArtifactBucketName}
ERROR_STATUS=${?}
if [[ ${ERROR_STATUS} -ne 0 ]]
then
  if [[ ${Region} == 'us-east-1' ]]
  then
    aws s3api create-bucket \
      --profile ${PROFILE} \
      --region ${Region} \
      --bucket ${CodeBuildArtifactBucketName}
  else
    aws s3api create-bucket \
      --profile ${PROFILE} \
      --region ${Region} \
      --bucket ${CodeBuildArtifactBucketName} \
      --create-bucket-configuration LocationConstraint=${Region}
  fi
fi

if [[ ! ${CodePipelineArtifactBucketName} == ${CodeBuildArtifactBucketName} ]]
then
  # Skip creation of the bucket if it already exists
  bucketExists ${PROFILE} ${CodePipelineArtifactBucketName}
  ERROR_STATUS=${?}
  if [[ ${ERROR_STATUS} -ne 0 ]]
  then
    if [[ ${Region} == 'us-east-1' ]]
    then
      aws s3api create-bucket \
        --profile ${PROFILE} \
        --region ${Region} \
        --bucket ${CodePipelineArtifactBucketName}
    else
      aws s3api create-bucket \
        --profile ${PROFILE} \
        --region ${Region} \
        --bucket ${CodePipelineArtifactBucketName} \
        --create-bucket-configuration LocationConstraint=${Region}
    fi
  fi
fi
