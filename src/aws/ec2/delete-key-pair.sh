#!/usr/bin/env bash

if [[ $# -lt 3 ]]
then
  echo "Usage: ${0} PROFILE REGION KEY_PAIR_NAME" >&2
  exit 1
fi

PROFILE=$1
REGION=$2
KEY_PAIR_NAME=$3

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh

keyPairExists ${PROFILE} ${REGION} ${KEY_PAIR_NAME}
if [[ $? -ne 0 ]]
then
  echo "The key pair '${KEY_PAIR_NAME}' does not exist."
  exit 0
fi

OUTPUT=$(aws ec2 delete-key-pair \
  --profile ${PROFILE} \
  --region ${REGION} \
  --key-name ${KEY_PAIR_NAME} \
)

echo ${OUTPUT}

NOTIFICATION_FILE=~/.ssh/${KEY_PAIR_NAME}-deletion.md
touch ${NOTIFICATION_FILE}
echo "The key pair '${KEY_PAIR_NAME}' has been deleted in AWS" > ${NOTIFICATION_FILE}
echo "View key pairs in ${REGION} at" >> ${NOTIFICATION_FILE}
echo "https://${REGION}.console.aws.amazon.com/ec2/v2/home?region=${REGION}#KeyPairs:sort=keyName" >> ${NOTIFICATION_FILE}
