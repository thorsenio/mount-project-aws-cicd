#!/usr/bin/env bash

# This script creates a CloudFormation stack that redirects the project's apex domain to its site
# subdomain (typically `www').
#
# Requirements:
# 1) The account must have a Route 53 hosted zone for the source domain, and
# 2) The apex domain name must have a verified ACM certificate (see `request-certificate.sh`
#    and `put-certificate-validation-record.sh`).

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
source ../aws-functions.sh
source ../../compute-variables.sh

SOURCE_DOMAIN_NAME=$(echoApexDomain ${SiteDomainName})
TARGET_DOMAIN_NAME=${SiteDomainName}
SUBDOMAIN=$(echoSubdomains ${TARGET_DOMAIN_NAME})

echo "Domain name to redirect: ${SOURCE_DOMAIN_NAME}"
echo "Redirection target: ${TARGET_DOMAIN_NAME}"

if [[ -z ${SUBDOMAIN} ]]; then
  echo -e "${SiteDomainName} has no subdomains.\nAborting." 1>&2
  exit 1
fi

STACK_NAME="redirect-${SOURCE_DOMAIN_NAME//./-}-to-${SUBDOMAIN}"
./put-redirection-stack.sh ${Profile} ${Region} ${SOURCE_DOMAIN_NAME} ${TARGET_DOMAIN_NAME} ${STACK_NAME}
