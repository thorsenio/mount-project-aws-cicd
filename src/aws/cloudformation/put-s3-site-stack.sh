#!/usr/bin/env bash

# This script updates a stack if it exists or creates the stack if it doesn't exist

CLOUDFORMATION_TEMPLATE='templates/s3-site.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source include/parse-stack-operation-options.sh "$@"
source ../aws-functions.sh
source ../../compute-variables.sh

STACK_NAME=${S3SiteStackName}

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${STACK_NAME})
if [[ ${PUT_MODE} == 'create' ]]; then
  if distributionExistsForCname ${Profile} ${SiteDomainName}; then
     echo -e "\nThe requested domain name '${SiteDomainName}' already points to another CloudFront distribution.\nAborting the stack operation.\n" 1>&2
     exit 1
  fi
fi

echo "Site domain name: ${SiteDomainName}"
echo "Project bucket name: ${ProjectBucketName}"

# TODO: REFACTOR: Modularize the functions in this script.
# TODO: REFACTOR: Share code with the ECS site-stack creation script

# Get the ARN of the ACM certificate for the domain name
CERTIFICATE_ARN=$(echoAcmCertificateArn ${Profile} ${CertifiedDomainName})
if [[ -z ${CERTIFICATE_ARN} ]]; then
  echo -e "No certificate was found for the domain '${CertifiedDomainName}'."
  ../acm/request-certificate.sh ${CertifiedDomainName}

  if [[ $? -ne 0 ]]; then
    exit 1
  fi

  CERTIFICATE_ARN=$(echoAcmCertificateArn ${Profile} ${CertifiedDomainName})
  if [[ -z ${CERTIFICATE_ARN} ]]; then
    exit 1
  fi
fi

# Get the apex domain name, which can be used to reference the hosted zone for the site domain name.
SOURCE_ZONE_APEX="$(echoApexDomain ${SiteDomainName})."
echo "Source domain apex: ${SOURCE_ZONE_APEX}"

if hostedZoneExistsForDomain ${Profile} ${SiteDomainName}; then
  APEX_HOSTED_ZONE_EXISTS=true
  echo -e "A Route 53 hosted zone was found for '${SOURCE_ZONE_APEX}'\n"
else
  APEX_HOSTED_ZONE_EXISTS=false
  echo 'Warning: An alias to CloudFront cannot be created automatically, because Route 53 is not'
  echo "managing DNS for '${SOURCE_ZONE_APEX}'. Once the stack has been created, create a CNAME record"
  echo -e "with the DNS provider to forward '${SiteDomainName}' traffic to CloudFront.\n"
fi

echo "Checking whether the SSL/TLS certificate for '${CertifiedDomainName}' has been validated ..."
if acmCertificateIsValidated ${Profile} "${CertifiedDomainName}"; then
  echo -e "The certificate has been validated.\n"
else
  if [[ ${APEX_HOSTED_ZONE_EXISTS} == false ]]; then
    # The domain is not managed by Route 53, so we can't automatically validate the domain.
    echo -e "Warning: The certificate has not been validated."
  else
    # TODO: MAYBE: Verify that a CNAME record for validation exists in Route 53
    # It will exist if `request-certificate.sh` was used to create the certificate, but otherwise
    # may not.
    echo "The certificate has not yet been validated."
    echo 'If `request-certificate.sh` was used to create the certificate, validation will happen automatically.'
    echo 'If `request-certificate.sh` was not used, verify that a CNAME record for validation has been added'
    echo "to the Route 53 hosted zone for '${SOURCE_ZONE_APEX}'. Use this command for details:"
    echo -e "  describe-cname-record.sh ${CertifiedDomainName}\n"
  fi
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
  --stack-name ${STACK_NAME} \
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

echoPutStackOutput ${STACK_NAME} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?

if [[ ${WAIT} == true ]]; then
  awaitStackOperationComplete ${Profile} ${Region} ${PUT_MODE} ${STACK_NAME}
  exitOnError $?
fi
