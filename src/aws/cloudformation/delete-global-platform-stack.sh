#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

../s3/empty-bucket.sh ${CfnTemplatesBucketName}

if [[ $? -ne 0 ]]; then
  echo -e "Aborting stack deletion.\n" 1>&2
  exit 1
fi

OUTPUT=$(aws cloudformation delete-stack \
  --profile=${Profile} \
  --region=${AWS_GLOBAL_REGION} \
  --stack-name=${GlobalPlatformStackName} \
)

EXIT_STATUS=$?
echoPutStackOutput 'delete' ${AWS_GLOBAL_REGION} ${EXIT_STATUS} ${OUTPUT}
