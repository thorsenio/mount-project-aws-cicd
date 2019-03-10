#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "${0}")

source ../aws-functions.sh
source ../../compute-variables.sh

if keyPairExists ${PROFILE} ${Region} ${KeyPairKeyName}; then
  # Key pair already exists
  # TODO: Maybe verify that the .pem file exists locally?
  echo "The key pair '${KeyPairKeyName}' already exists and will be re-used."
  exit 0
fi

OUTPUT=$(aws ec2 create-key-pair \
  --profile ${PROFILE} \
  --region ${Region} \
  --key-name ${KeyPairKeyName} \
)

if [[ ${?} -ne 0 ]]
then
  echo "The key pair could not be created." 1>&2
  echo ${OUTPUT}
  exit 1
fi

# TODO: Allow a different SSH key directory to be specified
IDENTITY_FILE=~/.ssh/${KeyPairKeyName}.pem

# Use `-r` parameter to get raw output instead of JSON-formatted output
echo ${OUTPUT} | jq -r '.KeyMaterial' > ${IDENTITY_FILE}

if [[ ${?} -ne 0 ]]
then
  echo "There was a problem parsing the key pair creation output." 1>&2
  exit 1
fi

# Protect the identity file
chmod 400 ${IDENTITY_FILE}

echo "A key pair named '${KeyPairKeyName}' has been generated and saved to ~/.ssh/${KeyPairKeyName}.pem."

# Remove the 'safe to delete' notification file, if left over from a previous deployment
NOTIFICATION_FILE=~/.ssh/${KeyPairKeyName}.pem-can-be-deleted.md
rm -f ${NOTIFICATION_FILE}
