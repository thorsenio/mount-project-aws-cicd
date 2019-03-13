#!/usr/bin/env bash

CLOUDFORMATION_TEMPLATE='templates/ecs-cloudfront-distribution.yml'

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../aws-functions.sh
source ../../compute-variables.sh

# Capture the mode that should be used put the stack: `create` or `update`
PUT_MODE=$(echoPutStackMode ${Profile} ${Region} ${CloudfrontDistributionStackName})

# Get the ARN of the ACM certificate for the domain name
CERTIFICATE_ARN=$(echoAcmCertificateArn ${Profile} ${CertifiedDomain})
if [[ -z ${CERTIFICATE_ARN} ]]
then
  echo "No certificate was found for the domain '${CertifiedDomain}'." 1>&2
  echo "The creation of the stack has been aborted." 1>&2
  exit 1
fi

APPLICATION_SERVER_ORIGIN=$(echoStackOutputValue ${Profile} ${Region} ${EcsClusterStackName} 'AlbDomainName')
if [[ -z ${APPLICATION_SERVER_ORIGIN} ]]; then
  echo -e "The application load balancer was not found.\nAborting."
  exit 1
fi

echo "Application server origin: ${APPLICATION_SERVER_ORIGIN}"

OUTPUT=$(aws cloudformation ${PUT_MODE}-stack \
  --profile ${Profile} \
  --region ${Region} \
  --stack-name ${CloudfrontDistributionStackName} \
  --template-body file://${CLOUDFORMATION_TEMPLATE} \
  --parameters \
    ParameterKey=AcmCertificateArn,ParameterValue=${CERTIFICATE_ARN} \
    ParameterKey=ApplicationServerOrigin,ParameterValue=${APPLICATION_SERVER_ORIGIN} \
    ParameterKey=SiteDomain,ParameterValue=${SiteDomain} \
    ParameterKey=SiteIndexDocument,ParameterValue=${SiteIndexDocument} \
  --capabilities \
    CAPABILITY_IAM \
)

EXIT_STATUS=$?
echoPutStackOutput ${PUT_MODE} ${Region} ${EXIT_STATUS} ${OUTPUT}
