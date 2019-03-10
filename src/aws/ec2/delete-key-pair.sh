#!/usr/bin/env bash

if [[ $# -lt 3 ]]
then
  echo "Usage: ${0} PROFILE REGION KEY_PAIR_NAME [--delete]" >&2
  exit 1
fi

PROFILE=$1
REGION=$2
KEY_PAIR_NAME=$3
DELETE_IDENTITY_FILE=${4:-'--no-delete'}

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh

if ! keyPairExists ${PROFILE} ${REGION} ${KEY_PAIR_NAME}; then
  echo "The key pair '${KEY_PAIR_NAME}' does not exist."
else
  OUTPUT=$(aws ec2 delete-key-pair \
    --profile ${PROFILE} \
    --region ${REGION} \
    --key-name ${KEY_PAIR_NAME} \
  )
  echo ${OUTPUT}
fi

if [[ ${DELETE_IDENTITY_FILE} == '--delete' ]]; then
  if [[ -f ~/.ssh/${KEY_PAIR_NAME} ]]; then
    rm -f ~/.ssh/${KEY_PAIR_NAME}.pem
    if [[ $? -eq 0 ]]; then
      echo "The identify file ~/.ssh/${KEY_PAIR_NAME}.pem has been deleted."
      exit 0
    else
      echo "The identify file ~/.ssh/${KEY_PAIR_NAME}.pem could not be deleted." 1>&2
      exit 1
    fi
  else
    echo "The identify file ~/.ssh/${KEY_PAIR_NAME}.pem does not exist."
  fi
else
  # If the identify file exists, place a notification file alongside it
  if [[ -f ~/.ssh/${KEY_PAIR_NAME} ]]; then
    NOTIFICATION_FILE=~/.ssh/${KEY_PAIR_NAME}-deletion.md
    touch ${NOTIFICATION_FILE}
    echo "The key pair '${KEY_PAIR_NAME}' has been deleted in AWS" > ${NOTIFICATION_FILE}
    echo "View key pairs in ${REGION} at" >> ${NOTIFICATION_FILE}
    echo "https://${REGION}.console.aws.amazon.com/ec2/v2/home?region=${REGION}#KeyPairs:sort=keyName" >> ${NOTIFICATION_FILE}
  else
    echo "The identify file does not exist."
  fi
fi
