#!/usr/bin/env bash

CLOUDFORMATION_TEMPLATE='templates/cloudfront-distribution.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${PROFILE} ${Region} ${CloudfrontDistributionStackName})

# Get the ARN of the ACM certificate for the domain name
CERTIFICATE_ARN=$(echoAcmCertificateArn ${PROFILE} ${CertifiedDomain})
if [[ -z ${CERTIFICATE_ARN} ]]
then
  echo "No certificate was found for the domain '${CertifiedDomain}'." 1>&2
  echo "The creation of the stack has been aborted." 1>&2
  exit 1
fi

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${PROFILE} \
  --region ${Region} \
  --stack-name ${CloudfrontDistributionStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=AcmCertificateArn,ParameterValue=${CERTIFICATE_ARN} \
    ParameterKey=SiteBucketName,ParameterValue=${ProjectBucketName} \
    ParameterKey=SiteDomain,ParameterValue=${SiteDomain} \
    ParameterKey=SiteErrorDocument,ParameterValue=${SiteErrorDocument} \
    ParameterKey=SiteIndexDocument,ParameterValue=${SiteIndexDocument} \
  --capabilities \
    CAPABILITY_IAM \
    CAPABILITY_NAMED_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
