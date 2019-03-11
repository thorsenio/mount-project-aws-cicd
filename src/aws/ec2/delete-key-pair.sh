#!/usr/bin/env bash

if [[ $# -lt 3 ]]
then
  echo "Usage: ${0} PROFILE REGION KEY_PAIR_NAME [--delete-identity-file]" >&2
  exit 1
fi

PROFILE=$1
REGION=$2
KEY_PAIR_NAME=$3
DELETE_IDENTITY_FILE=${4:-'--no-delete-identity-file'}
IDENTITY_FILE=~/.ssh/${KEY_PAIR_NAME}.pem

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh

if ! keyPairExists ${PROFILE} ${REGION} ${KEY_PAIR_NAME}; then
  echo "The key pair '${KEY_PAIR_NAME}' does not exist in AWS IAM."
else
  OUTPUT=$(aws ec2 delete-key-pair \
    --profile ${PROFILE} \
    --region ${REGION} \
    --key-name ${KEY_PAIR_NAME} \
  )
  echo ${OUTPUT}
fi

if [[ -f ${IDENTITY_FILE} ]]; then
  if [[ ${DELETE_IDENTITY_FILE} == '--delete-identity-file' ]]; then
    rm -f ${IDENTITY_FILE}
    if [[ $? -eq 0 ]]; then
      echo "The identity file ${IDENTITY_FILE} has been deleted."
      exit 0
    else
      echo "The identity file ${IDENTITY_FILE} could not be deleted." 1>&2
      exit 1
    fi
  else
    # Deletion was not requested, so place a notification alongside the identity file
    NOTIFICATION_FILE=~/.ssh/${KEY_PAIR_NAME}.pem-can-be-deleted.md
    touch ${NOTIFICATION_FILE}
    echo "The key pair '${KEY_PAIR_NAME}' has been deleted in AWS IAM" > ${NOTIFICATION_FILE}
    echo "View key pairs in ${REGION} at" >> ${NOTIFICATION_FILE}
    echo "https://${REGION}.console.aws.amazon.com/ec2/v2/home?region=${REGION}#KeyPairs:sort=keyName" >> ${NOTIFICATION_FILE}

    echo "The key pair '${KEY_PAIR_NAME}' is no longer needed."
    echo "The identity file ${IDENTITY_FILE} can be deleted."
  fi
else
  echo "The identity file was not found at ${IDENTITY_FILE}."
fi
