#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# TODO: Allow a different SSH key directory to be specified
IDENTITY_FILE="${KeyPairKeyName}.pem"
IDENTITY_FILEPATH=~/.ssh/${IDENTITY_FILE}

if keyPairExists ${Profile} ${Region} ${KeyPairKeyName}; then
  # Key pair already exists; make sure the identity file also exists
  if [[ -f ${IDENTITY_FILEPATH} ]]; then
    echo "The key pair '${KeyPairKeyName}' already exists and will be re-used."
    exit 0
  fi
else
  if [[ -f ${IDENTITY_FILEPATH} ]]; then
    echo -e "The identity file '${IDENTITY_FILEPATH}' cannot be created: the file already exists.\nAborting." 1>&2
    exit 1
  fi
fi

OUTPUT=$(aws ec2 create-key-pair \
  --profile ${Profile} \
  --region ${Region} \
  --key-name ${KeyPairKeyName} \
)
if [[ $? -ne 0 ]]
then
  echo "The key pair could not be created." 1>&2
  echo ${OUTPUT}
  exit 1
fi

# Use `-r` parameter to get raw output instead of JSON-formatted output
echo ${OUTPUT} | jq -r '.KeyMaterial' > ${IDENTITY_FILEPATH}
if [[ $? -ne 0 ]]
then
  echo "There was a problem parsing the key pair creation output." 1>&2
  exit 1
fi

# Protect the identity file
chmod 400 ${IDENTITY_FILEPATH}

echo "A key pair named '${KeyPairKeyName}' has been generated and saved to ~/.ssh/${KeyPairKeyName}.pem."

# Remove the 'safe to delete' notification file, if left over from a previous deployment
NOTIFICATION_FILE=${IDENTITY_FILEPATH}-can-be-deleted.md
rm -f ${NOTIFICATION_FILE}
