#!/usr/bin/env bash

# This script creates a CloudFormation stack that redirects the `www` subdomain to the project's
# apex.
#
# Requirements:
# 1) The account must have a Route 53 hosted zone for the source domain, and
# 2) The `www` subdomain name must have a verified ACM certificate (see `request-certificate.sh`
#    and `put-certificate-validation-record.sh`).

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../functions.sh
source ../../compute-variables.sh

TARGET_DOMAIN_NAME=$(echoApexDomain ${SiteDomainName})
if [[ -z ${TARGET_DOMAIN_NAME} ]]; then
  echo -e "The apex of ${SiteDomainName} could not be determined.\nAborting." 1>&2
  exit 1
fi

SOURCE_DOMAIN_NAME="www.${TARGET_DOMAIN_NAME}"
STACK_NAME="redirect-www-to-${TARGET_DOMAIN_NAME//./-}"

echo "Domain name to redirect: ${SOURCE_DOMAIN_NAME}"
echo "Redirection target: ${TARGET_DOMAIN_NAME}"

./put-redirection-stack.sh ${SOURCE_DOMAIN_NAME} ${TARGET_DOMAIN_NAME} ${STACK_NAME}
