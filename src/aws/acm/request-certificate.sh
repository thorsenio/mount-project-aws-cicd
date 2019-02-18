#!/usr/bin/env bash

# This script requests a TLS/SSL certificate for the specified domain

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

source ../aws-functions.sh
source ../../compute-variables.sh

# All certificates must be created in `us-east-1`
GLOBAL_REGION='us-east-1'

# Generate an idempotency token that is unique for the requested domain & today's date.
# If a fresh certificate request is needed for the same domain on the same date, increment the
# attempt number
DATE_STRING=$(date -I)
IDEMPOTENCY_TOKEN=$(printf "${DOMAIN_NAME} ${DATE_STRING} ${ATTEMPT_NUMBER}" | md5sum | cut -d ' ' -f 1)

OUTPUT=$(aws acm request-certificate \
  --profile ${PROFILE} \
  --region ${GLOBAL_REGION} \
  --domain-name=${DOMAIN_NAME} \
  --validation-method=DNS \
  --idempotency-token=${IDEMPOTENCY_TOKEN}
)

if [[ ${?} -ne 0 ]]
then
  echo 'AWS responded with an error to the request for a certificate' 1>&2
  exit 1
fi

echo ${OUTPUT}
CERTIFICATE_ARN=$(echo ${OUTPUT} | jq '.CertificateArn' | cut -d\" -f 2)
echo "Certificate ARN: ${CERTIFICATE_ARN}"

OUTPUT=$(aws acm describe-certificate \
  --profile ${PROFILE} \
  --region us-east-1 \
  --certificate-arn ${CERTIFICATE_ARN}
)

DNS_VALIDATION=$(echo ${OUTPUT} | jq '.Certificate.DomainValidationOptions[0]')
RECORD_NAME=$(echo ${DNS_VALIDATION} | jq '.ResourceRecord.Name' | cut -d\" -f 2)
RECORD_VALUE=$(echo ${DNS_VALIDATION} | jq '.ResourceRecord.Value' | cut -d\" -f 2)

echo ${OUTPUT} | jq '.'
echo
echo "CNAME record name: ${RECORD_NAME}"
echo "CNAME record value: ${RECORD_VALUE}"
