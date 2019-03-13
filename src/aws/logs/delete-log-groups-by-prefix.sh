#!/usr/bin/env bash

# This script deletes those of the project's log groups in CloudWatch Logs that begin with the
# specified prefix.


if [[ $# -ne 1 ]]
then
  echo "Usage: $0 PREFIX" 1>&2
  exit 1
fi

PREFIX=$1

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../compute-variables.sh

for LOG_GROUP in $(
  aws logs describe-log-groups \
    --profile ${Profile} \
    --region ${Region} \
    --log-group-name-prefix ${PREFIX} \
    --query 'logGroups[*].logGroupName' \
    --output text); do
  echo "Deleting ${LOG_GROUP}"
  aws logs delete-log-group \
  --profile ${Profile} \
  --region ${Region} \
  --log-group-name ${LOG_GROUP};
done
