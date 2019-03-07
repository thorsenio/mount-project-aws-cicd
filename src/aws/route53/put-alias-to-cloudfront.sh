#!/usr/bin/env bash

# This script creates a Route 53 record set that sets the specified DNS name to be an alias for
# the specified target

if [[ $# -lt 2 ]]
then
  echo "Usage: $0 ALIAS_DNS_NAME TARGET_DNS_NAME" >&2
  exit 1
fi

ALIAS_DNS_NAME=$1
TARGET_DNS_NAME=$2

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
source ../aws-constants.sh
source ../aws-functions.sh
source ../../compute-variables.sh

FQ_ALIAS=$(echoFqdn ${ALIAS_DNS_NAME})

# Use the apex domain name to look up the Hosted Zone ID
APEX_DOMAIN=$(echoApexDomain ${ALIAS_DNS_NAME})
HOSTED_ZONE_ID=$(echoHostedZoneIdByApex ${PROFILE} ${APEX_DOMAIN})

echo "Apex domain: ${APEX_DOMAIN}"
echo "Hosted zone ID: ${HOSTED_ZONE_ID}"

if [[ -z ${HOSTED_ZONE_ID} ]]; then
  echo "The hosted zone ID could not be parsed" 1>&2
  exit 1
fi

read -r -d '' CHANGES <<-EOF
  {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "${FQ_ALIAS}",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "${CLOUDFRONT_HOSTED_ZONE_ID}",
            "DNSName": "${TARGET_DNS_NAME}",
            "EvaluateTargetHealth": false
          }
        }
      }
    ]
  }
EOF

aws route53 change-resource-record-sets \
  --profile ${PROFILE} \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --change-batch "${CHANGES}"

if [[ $? -ne 0 ]]; then
  echo "There was an error creating the Alias record" 1>&2
  exit 1
fi
