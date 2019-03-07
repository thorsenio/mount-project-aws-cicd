#!/usr/bin/env bash

# The next statement will fail unless this script is sourced relative to the
# sourcing script (don't use an absolute path)
THIS_SCRIPT_DIR=$(dirname $(realpath ${PWD}/${BASH_SOURCE[0]}))
cd ${THIS_SCRIPT_DIR} > /dev/null
source ./aws-constants.sh
#source ../functions.sh
cd - > /dev/null

bucketExists () {

  local PROFILE=$1
  local BUCKET_NAME=$2

  aws s3api head-bucket \
    --profile ${PROFILE} \
    --bucket ${BUCKET_NAME} \
    &> /dev/null
}

codecommitRepoExists () {

  local PROFILE=$1
  local REGION=$2
  local REPOSITORY_NAME=$3

  # This command will generate an error if the repo doesn't exist
  aws codecommit get-repository \
    --profile ${PROFILE} \
    --region ${REGION} \
    --repository-name ${REPOSITORY_NAME} \
    &> /dev/null
}

ecrRepoExists () {

  local PROFILE=$1
  local REGION=$2
  local REPOSITORY_NAME=$3

  # This command will generate an error if the repo doesn't exist
  aws ecr describe-repositories \
    --profile ${PROFILE} \
    --region ${REGION} \
    --repository-names "${REPOSITORY_NAME}" \
    &> /dev/null
}

iamRoleExists () {

  local PROFILE=$1
  local REGION=$2
  local ROLE_NAME=$3

  aws iam get-role \
    --profile ${PROFILE} \
    --region ${REGION} \
    --role-name ${ROLE_NAME} \
    &> /dev/null
}

keyPairExists () {

  local PROFILE=$1
  local REGION=$2
  local KEY_PAIR_NAME=$3

  aws ec2 describe-key-pairs \
    --profile ${PROFILE} \
    --region ${REGION} \
    --key-names ${KEY_PAIR_NAME} \
    &> /dev/null
}

# TODO: REFACTOR: Add parameter checking and usage note
stackExists () {

  local PROFILE=$1
  local REGION=$2
  local STACK_NAME=$3

  aws cloudformation describe-stacks \
    --profile ${PROFILE} \
    --region ${REGION} \
    --stack-name ${STACK_NAME} \
    &> /dev/null
}

# Echo the ARN of the ACM certificate for the specified domain
echoAcmCertificateArn () {

  local PROFILE=$1
  local DOMAIN_NAME=$2
  local AWS_GLOBAL_REGION='us-east-1'

  local ACM_CERTIFICATE_ARN=$(
    aws acm list-certificates \
      --profile ${PROFILE} \
      --region ${AWS_GLOBAL_REGION} \
    | jq ".CertificateSummaryList[] | select(.DomainName==\"${DOMAIN_NAME}\").CertificateArn" \
    | cut -d \" -f 2 \
  )

  echo ${ACM_CERTIFICATE_ARN}
}

echoCountAzsInRegion () {

  local PROFILE=$1
  local REGION=$2

  aws ec2 describe-availability-zones \
    --profile ${PROFILE} \
    --region ${REGION} \
    --query 'AvailabilityZones[*] | length(@)'
}

# Echo the Hosted Zone ID for the specified Apex domain name
echoHostedZoneIdByApex () {

  local PROFILE=$1
  local APEX_DOMAIN_NAME=$2

  local HOSTED_ZONE_ID_VALUE=$(aws route53 list-hosted-zones-by-name \
    --profile ${PROFILE} \
    --dns-name ${APEX_DOMAIN_NAME} \
    --max-items 1 \
    --query "HostedZones[?Name=='${APEX_DOMAIN_NAME}.']| [0].Id" \
  )
  if [[ -z "${HOSTED_ZONE_ID_VALUE}" ]]; then
    echo ''
    return 1
  fi

  local HOSTED_ZONE_ID=$(echo ${HOSTED_ZONE_ID_VALUE:1:-1} | cut -d / -f 3)
  echo ${HOSTED_ZONE_ID}
  return 0
}

# Echo the Route 53 Hosted Zone ID for the specified Apex domain name
echoS3HostedZoneIdByRegion () {

  local REGION=$1

  HOSTED_ZONE_ID=${S3_HOSTED_ZONE_ID_REGION_MAP[${REGION}]}

  if [[ -z "${HOSTED_ZONE_ID}" ]]; then
    echo ''
    return 1
  fi

  echo ${HOSTED_ZONE_ID}
  return 0
}

echoPutStackMode () {

  local PROFILE=$1
  local REGION=$2
  local STACK_NAME=$3

  if stackExists ${PROFILE} ${REGION} ${STACK_NAME}; then
    echo 'update'
  else
    echo 'create'
  fi
  return 0
}

echoPutStackOutput () {

  local PUT_MODE=$1
  local REGION=$2
  local EXIT_STATUS=$3

  shift 3
  local OUTPUT=$*

  if [[ ${EXIT_STATUS} -ne 0 ]]; then
    echo "The request to ${PUT_MODE} the stack was not accepted by AWS." 1>&2
    echo ${OUTPUT} 1>&2
    return 1
  fi

  echo "The request to ${PUT_MODE} the stack was accepted by AWS."
  echo "View the stack's status at https://${REGION}.console.aws.amazon.com/cloudformation/home?region=${REGION}#/stacks?filter=active"
  echo ${OUTPUT} | jq '.'
  return 0
}
