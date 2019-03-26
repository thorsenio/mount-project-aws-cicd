#!/usr/bin/env bash

# This script requests a TLS/SSL certificate for the specified domain

# --- Behaviour tests
# If the requested certificate already exists, the script should exit with a failure code.
# If the domain is managed by Route 53, a validation record should be created.

if [[ $# -lt 1 || $# -gt 2 ]]
then
  echo "Usage: $0 DOMAIN_NAME [ATTEMPT_NUMBER]" >&2
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

if acmCertificateExists ${Profile} ${DOMAIN_NAME}; then
  echo -e "\nA certificate for ${DOMAIN_NAME} already exists in AWS Certificate Manager."
  echo -e "View certificates at https://console.aws.amazon.com/acm/home?region=us-east-1#/\n"
  exit 1
fi

# Generate an idempotency token that is unique for the requested domain & today's date.
# If a fresh certificate request is needed for the same domain on the same date, increment the
# attempt number
DATE_STRING=$(date -I)
IDEMPOTENCY_TOKEN=$(printf "${DOMAIN_NAME} ${DATE_STRING} ${ATTEMPT_NUMBER}" | md5sum | cut -d ' ' -f 1)

echo "Requesting an SSL/TLS certificate for '${DOMAIN_NAME}' ..."
OUTPUT=$(aws acm request-certificate \
  --profile ${Profile} \
  --region ${AWS_GLOBAL_REGION} \
  --domain-name=${DOMAIN_NAME} \
  --validation-method=DNS \
  --idempotency-token=${IDEMPOTENCY_TOKEN}
)

if [[ $? -ne 0 ]]; then
  echo 'AWS responded with an error to the request for a certificate' 1>&2
  exit 1
fi

echo ${OUTPUT}
CERTIFICATE_ARN=$(echo ${OUTPUT} | jq '.CertificateArn' | cut -d \" -f 2)
echo "Certificate ARN: ${CERTIFICATE_ARN}"

CERTIFICATE_EXISTS=false

echo "Waiting for the certificate to be created ..."
# TODO: Limit the number of attempts
while [[ ${CERTIFICATE_EXISTS} == false ]]; do
  sleep 10s
  if acmCertificateExists ${Profile} ${DOMAIN_NAME}; then
    CERTIFICATE_EXISTS=true
    echo 'The certificate has been created.'
  fi
done

if [[ ${CERTIFICATE_EXISTS} == false ]]; then
  echo "Error: The certificate could not be created."
  exit 1
fi

# From this point don't exit with an error status; the certificate has been created.
# Troubleshooting of validation can be regarded as a separate issue.

if hostedZoneExistsForDomain ${Profile} ${DOMAIN_NAME}; then
  # The domain is managed by Route 53, so add a CNAME record to validate the certificate.
  ../route53/put-certificate-validation-record.sh ${Profile} ${DOMAIN_NAME}
  awaitCertificateValidation ${Profile} ${CERTIFICATE_ARN}
else
  ZONE_APEX="$(echoApexDomain ${DOMAIN_NAME})."
  echo "Warning: The certificate cannot be validated automatically, because the '${ZONE_APEX}'"
  echo -e "domain is not managed by Route 53.\n"

  # Describe the details of the CNAME record to validate the certificate, then exit.
  ../acm/describe-cname-record.sh ${CertifiedDomainName}
fi
