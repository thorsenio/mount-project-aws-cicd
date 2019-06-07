#!/usr/bin/env bash

# This script creates a Route 53 record set that sets the specified domain
# name to be an alias for the application load balancer in the project's stack.
# If no domain is specified, the project's site domain name is used.

if [[ $# -gt 1 ]]
then
  echo "Usage: $0 [ALIAS_DNS_NAME]" >&2
  exit 1
fi

ALIAS_DNS_NAME=$1

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

if [[ $# -eq 1 ]]; then
  ALIAS_DNS_NAME=$1
else
  ALIAS_DNS_NAME=${SiteDomainName}
fi

echo "Processing request:"
echo "|  Alias: ${ALIAS_DNS_NAME}"
echo "|  Alias target: application load balancer for the '${DeploymentId}' deployment"

FQ_ALIAS=$(echoFqdn ${ALIAS_DNS_NAME})

# Use the apex domain name to look up the Hosted Zone ID
APEX_DOMAIN=$(echoApexDomain ${ALIAS_DNS_NAME})
HOSTED_ZONE_ID=$(echoHostedZoneIdByApex ${Profile} ${APEX_DOMAIN})

if [[ -z ${HOSTED_ZONE_ID} ]]; then
  echo -e "The hosted zone ID for '${APEX_DOMAIN}'could not be parsed.\nAborting." 1>&2
  exit 1
fi

# Get the load balancer's domain name
ALB_DOMAIN_NAME=$(echoStackOutputValue ${Profile} ${Region} ${EcsClusterStackName} 'AlbDomainName')
if [[ -z ${ALB_DOMAIN_NAME} ]]; then
  echo -e "The application load balancer was not found.\nAborting."
  exit 1
fi

# Use the S3 bucket's region to look up the Hosted Zone ID
# TODO: Allow buckets in regions other than the project's region
ELB_HOSTED_ZONE_ID=$(getElbHostedZoneIdByRegion ${Region})
#TARGET_DNS_NAME="elasticloadbalancing.${Region}.amazonaws.com"

if [[ -z ${ELB_HOSTED_ZONE_ID} ]]; then
  echo "The hosted zone ID of the Elastic Load Balancer endpoint for the '${Region}' region could not be found.\Aborting." 1>&2
  exit 1
fi

echo "Site's hosted zone ID: ${HOSTED_ZONE_ID}"
echo "ALB's hosted zone ID: ${ELB_HOSTED_ZONE_ID}"

read -r -d '' CHANGES <<-EOF
  {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "${FQ_ALIAS}",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "${ELB_HOSTED_ZONE_ID}",
            "DNSName": "${ALB_DOMAIN_NAME}",
            "EvaluateTargetHealth": false
          }
        }
      }
    ]
  }
EOF

aws route53 change-resource-record-sets \
  --profile ${Profile} \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --change-batch "${CHANGES}"

if [[ $? -ne 0 ]]; then
  echo "There was an error creating the Alias record" 1>&2
  exit 1
fi
