#!/usr/bin/env bash

# This script displays the details of the CNAME record that validates the ACM certificate
# for the specified domain name

if [[ $# -lt 1 ]]
then
  echo "Usage: $0 DOMAIN_NAME" >&2
  exit 1
fi

# Required arguments
DOMAIN_NAME=$1

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
source ../aws-functions.sh
source ../../compute-variables.sh

CERTIFICATE_ARN=$(echoAcmCertificateArn ${Profile} ${DOMAIN_NAME})

if [[ -z ${CERTIFICATE_ARN} ]]
then
  echo "No certificate was found for the domain '${DOMAIN_NAME}'." 1>&2
  exit 1
fi

DESCRIPTION=$(aws acm describe-certificate \
  --profile ${Profile} \
  --region ${AWS_GLOBAL_REGION} \
  --certificate-arn ${CERTIFICATE_ARN}
)

DNS_VALIDATION=$(echo ${DESCRIPTION} | jq '.Certificate.DomainValidationOptions[0]')
RECORD_NAME=$(echo ${DNS_VALIDATION} | jq '.ResourceRecord.Name' | cut -d\" -f 2)
RECORD_VALUE=$(echo ${DNS_VALIDATION} | jq '.ResourceRecord.Value' | cut -d\" -f 2)

echo 'To validate the certificate, create the following CNAME record in the zone records for'
echo "'$(echoApexDomain ${DOMAIN_NAME})':"
echo "  host: ${RECORD_NAME}"
echo -e "  points to: ${RECORD_VALUE}\n"
