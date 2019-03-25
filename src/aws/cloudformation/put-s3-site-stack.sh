#!/usr/bin/env bash

# This script updates a stack if it exists or creates the stack if it doesn't exist

CLOUDFORMATION_TEMPLATE='templates/s3-site.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

echo "Project bucket name: ${ProjectBucketName}"

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

TEMPLATE_BASENAME=$(echo ${CLOUDFORMATION_TEMPLATE} | awk -F '/' '{ print $NF }' | cut -d. -f1)

# TODO: REFACTOR: Use a function to generate ParameterKey,ParameterValue strings
OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${SiteStackName} \
  --template-body file://${TEMPLATE_BASENAME}--expanded.yml \
  --parameters \
    ParameterKey=AcmCertificateArn,ParameterValue=${CERTIFICATE_ARN} \
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
  --capabilities \
    CAPABILITY_AUTO_EXPAND \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}

if [[ ${EXIT_STATUS} -eq 0 ]]
then
  echo 'The stack will not be created unless you create (or have already created)'
  echo 'a CNAME record to allow AWS to validate the domain.'
  echo "To display the CNAME hostname and value, run \`describe-cname-record.sh '${CertifiedDomainName}'\`"
fi
