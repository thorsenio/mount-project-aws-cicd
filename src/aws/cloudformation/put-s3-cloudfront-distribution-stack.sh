#!/usr/bin/env bash

CLOUDFORMATION_TEMPLATE='templates/s3-cloudfront-distribution.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source include/parse-stack-operation-options.sh "$@"
source ../aws-functions.sh
source ../../compute-variables.sh

STACK_NAME=${CloudfrontDistributionStackName}

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${STACK_NAME})

# Get the ARN of the ACM certificate for the domain name
CERTIFICATE_ARN=$(echoAcmCertificateArn ${Profile} ${CertifiedDomainName})
if [[ -z ${CERTIFICATE_ARN} ]]
then
  echo "No certificate was found for the domain '${CertifiedDomainName}'." 1>&2
  echo "The creation of the stack has been aborted." 1>&2
  exit 1
fi

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${STACK_NAME} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=AcmCertificateArn,ParameterValue=${CERTIFICATE_ARN} \
    ParameterKey=SiteBucketName,ParameterValue=${ProjectBucketName} \
    ParameterKey=SiteDomainName,ParameterValue=${SiteDomainName} \
    ParameterKey=SiteErrorDocument,ParameterValue=${SiteErrorDocument} \
    ParameterKey=SiteIndexDocument,ParameterValue=${SiteIndexDocument} \
  --capabilities \
    CAPABILITY_IAM \
    CAPABILITY_NAMED_IAM \
)

echoPutStackOutput ${STACK_NAME} ${PUT_MODE} ${Region} $? ${OUTPUT}
exitOnError $?

if [[ ${WAIT} == true ]]; then
  awaitStackOperationComplete ${Profile} ${Region} ${PUT_MODE} ${STACK_NAME}
  exitOnError $?
fi
