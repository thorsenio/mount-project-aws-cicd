#!/usr/bin/env bash

# This script updates a stack if it exists or creates the stack if it doesn't exist

CLOUDFORMATION_TEMPLATE='templates/s3-site.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

echo "Project bucket name: ${ProjectBucketName}"

# Get the apex domain name, which can be used to reference the hosted zone for the site domain name.
SOURCE_ZONE_APEX="$(echoApexDomain ${SiteDomainName})."

echo "Source domain apex: ${SOURCE_ZONE_APEX}"

if hostedZoneExistsForDomain ${Profile} ${SiteDomainName}; then
  APEX_HOSTED_ZONE_EXISTS=true
  echo "A Route 53 hosted zone was found for '${SOURCE_ZONE_APEX}'"
else
  APEX_HOSTED_ZONE_EXISTS=false
  echo "Warning: No hosted zone exists for '${SOURCE_ZONE_APEX}', so an alias record cannot be created."
  echo "To direct '${SiteDomainName}' traffic to the CDN, create a CNAME record with the DNS provider."
fi

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${SiteStackName})

# Get the ARN of the ACM certificate for the domain name
CERTIFICATE_ARN=$(echoAcmCertificateArn ${Profile} ${CertifiedDomainName})
if [[ -z ${CERTIFICATE_ARN} ]]
then
  echo "No certificate was found for the domain '${CertifiedDomainName}'."
  echo "The creation of the stack has been aborted."
  exit 1
fi

./package.sh ${CLOUDFORMATION_TEMPLATE}

if [[ $? -ne 0 ]]
then
  exit 1
fi

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d . -f 1)

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${SiteStackName} \
  --template-body file://${TEMPLATE_BASENAME}--expanded.yml \
  --parameters \
    ParameterKey=AcmCertificateArn,ParameterValue=${CERTIFICATE_ARN} \
    ParameterKey=ApexHostedZoneExists,ParameterValue=${APEX_HOSTED_ZONE_EXISTS} \
    ParameterKey=CloudFrontHostedZoneId,ParameterValue=${CLOUDFRONT_HOSTED_ZONE_ID} \
    ParameterKey=DeploymentId,ParameterValue=${DeploymentId} \
    ParameterKey=PlatformCommitHash,ParameterValue=${PlatformCommitHash} \
    ParameterKey=PlatformId,ParameterValue=${PlatformId} \
    ParameterKey=PlatformVersionLabel,ParameterValue=${PlatformVersionLabel} \
    ParameterKey=ProjectCommitHash,ParameterValue=${ProjectCommitHash} \
    ParameterKey=ProjectVersionLabel,ParameterValue=${ProjectVersionLabel} \
    ParameterKey=SiteBucketName,ParameterValue=${ProjectBucketName} \
    ParameterKey=SiteDomainName,ParameterValue=${SiteDomainName} \
    ParameterKey=SiteErrorDocument,ParameterValue=${SiteErrorDocument} \
    ParameterKey=SiteIndexDocument,ParameterValue=${SiteIndexDocument} \
    ParameterKey=SourceDomainName,ParameterValue=${SiteDomainName} \
    ParameterKey=SourceZoneApex,ParameterValue=${SOURCE_ZONE_APEX} \
  --capabilities \
    CAPABILITY_AUTO_EXPAND \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}

if [[ ${EXIT_STATUS} -ne 0 ]]; then
  exit 1
fi

if [[ ${APEX_HOSTED_ZONE_EXISTS} == false ]]; then
  echo "Checking whether the SSL/TLS certificate for '${CertifiedDomainName}' has been validated ..."
  if acmCertificateIsValidated ${Profile} "${CertifiedDomainName}"; then
    # The certificate has been validated, so nothing else needs to be done
    echo "The certificate has been validated."
  else
    echo "Warning: The SSL/TLS certificate for '${CertifiedDomainName}' has not been validated."
    echo "The stack will not be created until the certificate has been validated."
  fi
fi
