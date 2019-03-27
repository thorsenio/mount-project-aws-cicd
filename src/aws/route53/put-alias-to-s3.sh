#!/usr/bin/env bash

# This script creates a Route 53 record set that sets the specified apex DNS
# name to be an alias for the S3 static site in a bucket of the same name

if [[ $# -ne 1 ]]
then
  echo "Usage: $0 ALIAS_DNS_NAME" >&2
  exit 1
fi

ALIAS_DNS_NAME=$1
BUCKET_NAME=${ALIAS_DNS_NAME}

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
source ../aws-functions.sh
source ../../compute-variables.sh

FQ_ALIAS=$(echoFqdn ${ALIAS_DNS_NAME})

# Use the apex domain name to look up the Hosted Zone ID
APEX_DOMAIN=$(echoApexDomain ${ALIAS_DNS_NAME})
HOSTED_ZONE_ID=$(echoHostedZoneIdByApex ${PROFILE} ${APEX_DOMAIN})

if [[ -z ${HOSTED_ZONE_ID} ]]; then
  echo -e "The hosted zone ID for '${APEX_DOMAIN}'could not be parsed.\nAborting." 1>&2
  exit 1
fi

# Verify that the bucket exists
if ! bucketExists ${PROFILE} ${BUCKET_NAME}; then
  echo -e "No bucket named '${BUCKET_NAME}' was found.\nAborting." 1>&2
  exit 1
fi

# Use the S3 bucket's region to look up the Hosted Zone ID
# TODO: Allow buckets in regions other than the project's region
S3_HOSTED_ZONE_ID=$(echoS3HostedZoneIdByRegion ${Region})
TARGET_DNS_NAME="s3-website.${Region}.amazonaws.com"

if [[ -z ${S3_HOSTED_ZONE_ID} ]]; then
  echo "The hosted zone ID of the S3 endpoint for the '${Region}' region could not be found.\Aborting." 1>&2
  exit 1
fi

echo "Hosted zone ID: ${HOSTED_ZONE_ID}"
echo "S3 hosted zone ID: ${S3_HOSTED_ZONE_ID}"

read -r -d '' CHANGES <<-EOF
  {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "${FQ_ALIAS}",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "${S3_HOSTED_ZONE_ID}",
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
