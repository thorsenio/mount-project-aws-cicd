#!/usr/bin/env bash

bucketExists () {

  local PROFILE=$1
  local BUCKET_NAME=$2

  aws s3api head-bucket \
    --profile ${PROFILE} \
    --bucket ${BUCKET_NAME} \
    &> /dev/null

  if [[ $? -eq 0 ]]
  then
    # Bucket exists
    return 0
  else
    # Bucket does not exist
    return 1
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
    # Role exists
    return 0
  else
    # Role does not exist
    return 1
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
    # Key pair exists
    return 0
  else
    # Key pair does not exist
    return 1
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
    # Stack exists
    return 0
  else
    # Stack does not exist
    return 1
  fi
}

# Echo the ARN of the ACM certificate created in the stack
echoAcmCertificateArn () {

  local PROFILE=$1
  local REGION=$2
  local STACK_NAME=$3

  local CLOUDFRONT_STACK_NAME=$(
    aws cloudformation describe-stack-resource \
      --profile ${PROFILE} \
      --region ${REGION} \
      --stack-name ${STACK_NAME} \
      --logical-resource-id CdnDistroStack \
    | jq '.StackResourceDetail.PhysicalResourceId' \
    | cut -d/ -f 2 \
  )

  local ACM_CERTIFICATE_ARN=$(
    aws cloudformation describe-stack-resource \
      --profile ${PROFILE} \
      --region ${REGION} \
      --stack-name ${CLOUDFRONT_STACK_NAME} \
      --logical-resource-id AcmCertificate \
    | jq '.StackResourceDetail.PhysicalResourceId' \
    | cut -d\" -f 2 \
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

# Echo the name of the S3 bucket that hosts the site, after locating it in the specified stack
# Assumptions: The bucket has the logical name `SiteBucket` and is created in the nested stack
# named `SiteBucketStack`
echoSiteBucketName () {

  local PROFILE=$1
  local REGION=$2
  local STACK_NAME=$3

  local BUCKET_STACK_NAME=$(
    aws cloudformation describe-stack-resource \
      --profile ${PROFILE} \
      --region ${REGION} \
      --stack-name ${STACK_NAME} \
      --logical-resource-id SiteBucketStack \
    | jq '.StackResourceDetail.PhysicalResourceId' \
    | cut -d/ -f 2 \
  ) &> /dev/null

  if [[ $? -ne 0 ]]
  then
    return 1
  fi

  local BUCKET_NAME=$(
    aws cloudformation describe-stack-resource \
      --profile ${PROFILE} \
      --region ${REGION} \
      --stack-name ${BUCKET_STACK_NAME} \
      --logical-resource-id SiteBucket \
    | jq '.StackResourceDetail.PhysicalResourceId' \
    | cut -d\" -f 2 \
  ) &> /dev/null

  if [[ $? -ne 0 ]]
  then
    return 1
  fi

  echo ${BUCKET_NAME}
}


echoPutStackMode () {

  local PROFILE=$1
  local REGION=$2
  local STACK_NAME=$3

  stackExists ${PROFILE} ${REGION} ${STACK_NAME}
  if [[ $? -eq 0 ]]
  then
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
    echo "View the stack at https://${REGION}.console.aws.amazon.com/cloudformation/home?region=${REGION}#/stacks?filter=active"
  else
    echo "The request to ${PUT_MODE} the stack was not accepted by AWS." 1>&2
    echo ${OUTPUT} 1>&2
    exit 1
  fi

  echo ${OUTPUT} | jq '.'
}
