#!/usr/bin/env bash

# This script creates a CNAME record to validate the ACM SSL/TLS certificate for the specified
# domain name. It assumes that
# 1) the certificate exists in ACM
# 2) a hosted zone for the domain exists in Route 53

if [[ $# -lt 2 || $# -gt 3 ]]
then
  echo "Usage: $0 PROFILE DOMAIN_NAME [ATTEMPT_NUMBER]" >&2
  exit 1
fi

# Required arguments
PROFILE=$1
DOMAIN_NAME=$2

# Optional argument
ATTEMPT_NUMBER=${3:-1}

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
source ../aws-constants.sh
source ../aws-functions.sh

CERTIFICATE_ARN=$(echoAcmCertificateArn ${PROFILE} ${DOMAIN_NAME})
if [[ -z ${CERTIFICATE_ARN} ]]
then
  echo "No certificate was found for the domain '${DOMAIN_NAME}'." 1>&2
  exit 1
fi

# Get the CNAME validation details for the certificate: domain name & value
DESCRIPTION=$(aws acm describe-certificate \
  --profile ${PROFILE} \
  --region ${AWS_GLOBAL_REGION} \
  --certificate-arn ${CERTIFICATE_ARN}
)

DNS_VALIDATION=$(echo ${DESCRIPTION} | jq '.Certificate.DomainValidationOptions[0]')
RECORD_NAME=$(echo ${DNS_VALIDATION} | jq '.ResourceRecord.Name' | cut -d\" -f 2)
RECORD_VALUE=$(echo ${DNS_VALIDATION} | jq '.ResourceRecord.Value' | cut -d\" -f 2)

echo "Create the following CNAME record in the zone records for $(echoApexDomain ${DOMAIN_NAME}):"
echo "hostname: ${RECORD_NAME}"
echo "value (redirect to): ${RECORD_VALUE}"

# Generate an idempotency token that is unique for the requested domain & today's date.
# If a fresh certificate request is needed for the same domain on the same date, increment the
# attempt number
IDEMPOTENCY_TOKEN=$(echoDailyIdempotencyToken ${DOMAIN_NAME} ${ATTEMPT_NUMBER})

# Use the apex domain name to look up the Hosted Zone ID
HOSTED_ZONE_APEX=$(echoApexDomain ${DOMAIN_NAME})
HOSTED_ZONE_ID=$(echoHostedZoneIdByApex ${PROFILE} ${HOSTED_ZONE_APEX})

echo "Hosted zone apex: ${HOSTED_ZONE_APEX}"
echo "Hosted zone ID: ${HOSTED_ZONE_ID}"

read -r -d '' CHANGES <<-EOF
  {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "${RECORD_NAME}",
          "Type": "CNAME",
          "TTL": 86400,
          "ResourceRecords": [
            {
              "Value": "${RECORD_VALUE}"
            }
          ]
        }
      }
    ]
  }
EOF

OUTPUT=$(aws route53 change-resource-record-sets \
  --profile ${PROFILE} \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --change-batch "${CHANGES}" \
)
if [[ $? -eq 0 ]]; then
  echo 'An SSL/TLS certificate validation record has been created in Route 53.'
  echo "View the certificate's status at https://console.aws.amazon.com/acm/home?region=us-east-1#/"
else
  echo 'There was an error creating the certificate validation record.' 1>&2
  exit 1
fi
