#!/usr/bin/env bash

if [[ $# -lt 1 || $# -gt 2 ]]
then
  echo "Usage: ${0} DOMAIN_NAME [ATTEMPT_NUMBER]" >&2
  exit 1
fi

# Required arguments
DOMAIN_NAME=$1

# Optional argument
ATTEMPT_NUMBER=${2:-1}

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

# source ../aws-functions.sh
source ../../compute-variables.sh

# Generate an idempotency token that is unique for the requested domain & today's date.
# If a fresh certificate request is needed for the same domain on the same date, increment the
# attempt number
DATE_STRING=$(date -I)
IDEMPOTENCY_TOKEN=$(printf "${DOMAIN_NAME} ${DATE_STRING} ${ATTEMPT_NUMBER}" | md5sum | cut -d ' ' -f 1)

OUTPUT=$(aws route53 create-hosted-zone \
  --profile ${PROFILE} \
  --name ${DOMAIN_NAME} \
  --caller-reference ${IDEMPOTENCY_TOKEN} \
  --hosted-zone-config Comment="Created by ${PlatformName}-${PlatformVersionLabel}" \
)

EXIT_STATUS=$?

echo ${OUTPUT} | jq '.'

exit ${EXIT_STATUS}
