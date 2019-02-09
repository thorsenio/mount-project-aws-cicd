#!/usr/bin/env bash

# This script displays the details of the CNAME record that validates the stack's ACM certificate

# Change to the directory of this script
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

CERTIFICATE_ARN=$(echoAcmCertificateArn ${PROFILE} ${Region} ${SiteStackName})

OUTPUT=$(aws acm describe-certificate \
  --profile ${PROFILE} \
  --region us-east-1 \
  --certificate-arn ${CERTIFICATE_ARN}
)

DNS_VALIDATION=$(echo ${OUTPUT} | jq '.Certificate.DomainValidationOptions[0]')
RECORD_NAME=$(echo ${DNS_VALIDATION} | jq '.ResourceRecord.Name' | cut -d\" -f 2)
RECORD_VALUE=$(echo ${DNS_VALIDATION} | jq '.ResourceRecord.Value' | cut -d\" -f 2)

echo
echo "Create the following CNAME record in the zone records for $(echo2ndLevelDomain ${SiteDomainName})"
echo "  hostname: ${RECORD_NAME}"
echo "  value (redirect to): ${RECORD_VALUE}"
