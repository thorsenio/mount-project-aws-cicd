#!/usr/bin/env bash

# Uncomment this block when any of the functions in `functions.sh` (non-AWS functions) are used
#THIS_SCRIPT_DIR=$(dirname $(realpath ${PWD}/${BASH_SOURCE[0]}))
#cd ${THIS_SCRIPT_DIR} > /dev/null
#source ../functions.sh
#cd - > /dev/null

bucketExists () {

  local PROFILE=$1
  local BUCKET_NAME=$2

  aws s3api head-bucket \
    --profile ${PROFILE} \
    --bucket ${BUCKET_NAME} \
    &> /dev/null

  if [[ $? -eq 0 ]]
  then
    true
  else
    false
  fi
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

  if [[ $? -eq 0 ]]
  then
    true
  else
    false
  fi
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

  if [[ $? -eq 0 ]]
  then
    true
  else
    false
  fi
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

  if [[ $? -eq 0 ]]
  then
    true
  else
    false
  fi
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

  if [[ $? -eq 0 ]]
  then
    true
  else
    false
  fi
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

  if [[ $? -eq 0 ]]
  then
    true
  else
    false
  fi
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

# Given a domain name, echo the first two levels of the domain name
# Example: Given `any.subdomain.example.com`, echo `example.com`
echo2ndLevelDomain () {
  local DOMAIN_NAME=$1
  local DOMAIN_LEVEL_2=$(echo ${DOMAIN_NAME} | awk -F '.' '{ print $(NF-1) }')
  local DOMAIN_LEVEL_1=$(echo ${DOMAIN_NAME} | awk -F '.' '{ print $NF }')
  echo "${DOMAIN_LEVEL_2}.${DOMAIN_LEVEL_1}"
}

echoCountAzsInRegion() {
  PROFILE=$1
  REGION=$2
  aws ec2 describe-availability-zones \
    --profile ${PROFILE} \
    --region ${REGION} \
    --query 'AvailabilityZones[*] | length(@)'
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

  if [[ ${EXIT_STATUS} -eq 0 ]]
  then
    echo "The request to ${PUT_MODE} the stack was accepted by AWS."
    echo "View the stack's status at https://${REGION}.console.aws.amazon.com/cloudformation/home?region=${REGION}#/stacks?filter=active"
  else
    echo "The request to ${PUT_MODE} the stack was not accepted by AWS." 1>&2
    echo ${OUTPUT} 1>&2
    exit 1
  fi

  echo ${OUTPUT} | jq '.'
}
