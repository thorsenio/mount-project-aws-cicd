#!/usr/bin/env bash

# Change to the directory of this script
cd $(dirname "${0}")

source ../aws-functions.sh
source ../../compute-variables.sh

aws s3api create-bucket \
  --profile ${PROFILE} \
  --region ${Region} \
  --bucket ${TemplateBucketName} \
  --create-bucket-configuration LocationConstraint=${Region}
