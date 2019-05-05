#!/usr/bin/env bash

# The next statement will fail unless this script is sourced relative to the
# sourcing script (don't use an absolute path)
THIS_SCRIPT_DIR=$(dirname $(realpath ${PWD}/${BASH_SOURCE[0]}))
cd ${THIS_SCRIPT_DIR} > /dev/null
source ./aws-constants.sh
source ../functions.sh
cd - > /dev/null


# Tests whether an ACM certificate exists for the specified domain
acmCertificateExists () {

  local PROFILE=$1
  local DOMAIN_NAME=$2

  COUNT=$(aws acm list-certificates \
    --profile ${PROFILE} \
    --region ${AWS_GLOBAL_REGION} \
    --query "CertificateSummaryList[?DomainName=='${DOMAIN_NAME}'] | length(@)" \
    --output text \
  )

  [[ $? -eq 0 && ! ${COUNT} == '0' ]]
}


# Tests whether an ACM certificate exists & has been validated for the specified domain
acmCertificateIsValidated () {

  local PROFILE=$1
  local DOMAIN_NAME=$2

  COUNT=$(aws acm list-certificates \
    --profile ${PROFILE} \
    --region ${AWS_GLOBAL_REGION} \
    --certificate-statuses ISSUED \
    --query "CertificateSummaryList[?DomainName=='${DOMAIN_NAME}'] | length(@)" \
    --output text \
  )

  [[ $? -eq 0 && ! ${COUNT} == '0' ]]
}

# Wait for the specified certificate to be validated.
# Return 0 if the validation was successful; otherwise, return 1.
awaitCertificateValidation () {

  local PROFILE=$1
  local CERTIFICATE_ARN=$2

  echo "Waiting for the certificate to be validated ..."
  aws acm wait certificate-validated \
    --profile ${PROFILE} \
    --region ${AWS_GLOBAL_REGION} \
    --certificate-arn ${CERTIFICATE_ARN}

  if [[ $? -eq 0 ]]; then
    echo -e "The certificate has been validated.\n"
    return 0
  else
    echo 'Warning: Certificate validation failed.'
    return 1
  fi
}

# Wait for the completion of the stack operation.
awaitStackOperationComplete () {
  local PROFILE=$1
  local REGION=$2
  local OPERATION=$3
  local STACK_NAME=$4

  echo "Waiting for CloudFormation to ${OPERATION} the stack (press Ctrl+C to stop waiting while allowing the operation to continue) ..."
  aws cloudformation wait stack-${OPERATION}-complete \
    --profile ${PROFILE} \
    --region ${REGION} \
    --stack-name ${STACK_NAME}

  if [[ $? -eq 0 ]]; then
    echo "The stack has been ${OPERATION}d."
    return 0
  else
    return 1
  fi
}


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

distributionExistsForCname () {

  local PROFILE=$1
  local CNAME=$2

  local DISTRIBUTION_ID=$(aws cloudfront list-distributions \
    --profile ${PROFILE} \
    --query "DistributionList.Items[?Aliases.Items[0]=='${CNAME}'].Id | [0]" \
  )

  if [[ -z ${DISTRIBUTION_ID} ||  ${DISTRIBUTION_ID} == 'null' ]]; then
    return 1
  fi

  return 0
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


hostedZoneExistsForDomain () {

  local PROFILE=$1
  local DOMAIN_NAME=$2

  local APEX_DOMAIN_NAME=$(echoApexDomain ${DOMAIN_NAME})
  if [[ -z ${APEX_DOMAIN_NAME} ]]; then
    return 1
  fi

  echoHostedZoneIdByApex ${PROFILE} ${APEX_DOMAIN_NAME} > /dev/null
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


# Echo the CloudFront Distribution ID for the specified CNAME
echoDistributionIdByCname () {

  local PROFILE=$1
  local CNAME=$2

  local DISTRIBUTION_ID=$(aws cloudfront list-distributions \
    --profile ${PROFILE} \
    --query "DistributionList.Items[?Aliases.Items[0]=='${CNAME}'].Id | [0]" \
  )

  if [[ -z ${DISTRIBUTION_ID} ||  ${DISTRIBUTION_ID} == 'null' ]]; then
    echo ''
    return 1
  fi

  echo ${DISTRIBUTION_ID:1:-1}
  return 0
}


# Echo the domain name for the specified CloudFront distribution ID
echoDomainNameByDistributionId () {

  local PROFILE=$1
  local DISTRIBUTION_ID=$2

  local DOMAIN_NAME=$(aws cloudfront get-distribution \
    --profile ${PROFILE} \
    --id ${DISTRIBUTION_ID} \
    --query 'Distribution.DomainName' \
    2> /dev/null
  )
  if [[ $? -ne 0 ]]; then
    echo ''
    return 1
  fi

  echo ${DOMAIN_NAME:1:-1}
  return 0
}


# Echo the endpoint address for the specified database instance
echoEndpointAddressByDbInstanceIdentifier () {

  local PROFILE=$1
  local REGION=$2
  local DB_INSTANCE_IDENTIFIER=$3

  local ENDPOINT_ADDRESS=$(aws rds describe-db-instances \
    --profile ${PROFILE} \
    --region ${Region} \
    --db-instance-identifier ${DB_INSTANCE_IDENTIFIER} \
    --max-items 1 \
    --query 'DBInstances[0].Endpoint.Address' \
    2> /dev/null
  )
  if [[ $? -ne 0 ]]; then
    echo ''
    return 1
  fi

  echo ${ENDPOINT_ADDRESS:1:-1}
  return 0
}


# Echo the Route 53 Hosted Zone ID for the specified Apex domain name
echoHostedZoneIdByApex () {

  local PROFILE=$1
  local APEX_DOMAIN_NAME=$2

  local HOSTED_ZONE_ID_VALUE=$(aws route53 list-hosted-zones-by-name \
    --profile ${PROFILE} \
    --dns-name ${APEX_DOMAIN_NAME} \
    --max-items 1 \
    --query "HostedZones[?Name=='${APEX_DOMAIN_NAME}.']| [0].Id" \
    --output text \
    2> /dev/null
  )
  if [[ $? -ne 0 || ${HOSTED_ZONE_ID_VALUE:0:4} == 'None' ]]; then
    echo ''
    return 1
  fi

  local HOSTED_ZONE_ID=$(echo ${HOSTED_ZONE_ID_VALUE} | cut -d / -f 3)
  echo ${HOSTED_ZONE_ID}
  return 0
}


# Echo the specified output value of the specified stack
echoStackOutputValue () {

  local PROFILE=$1
  local REGION=$2
  local STACK_NAME=$3
  local OUTPUT_KEY=$4

  local OUTPUT_VALUE=$(aws cloudformation describe-stacks \
    --profile ${PROFILE} \
    --region ${REGION} \
    --stack-name ${STACK_NAME} \
    --max-items 1 \
    --query "Stacks[0] | Outputs[?OutputKey=='${OUTPUT_KEY}'] | [0].OutputValue" \
    --output text
    2> /dev/null
  )

  if [[ $? -ne 0 || ${OUTPUT_VALUE} == 'None' ]]; then
    echo ''
    return 1
  fi

  echo ${OUTPUT_VALUE}
  return 0
}


# Echo the parameter value of the specified parameter key of the specified stack
echoStackParameterValue () {

  local PROFILE=$1
  local REGION=$2
  local STACK_NAME=$3
  local PARAMETER_KEY=$4

  local PARAMETER_VALUE=$(aws cloudformation describe-stacks \
    --profile ${PROFILE} \
    --region ${REGION} \
    --stack-name ${STACK_NAME} \
    --max-items 1 \
    --query "Stacks[0] | Parameters[?ParameterKey=='${PARAMETER_KEY}'] | [0].ParameterValue" \
    --output text
    2> /dev/null
  )

  if [[ $? -ne 0 || ${PARAMETER_VALUE} == 'None' ]]; then
    echo ''
    return 1
  fi

  echo ${PARAMETER_VALUE}
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

  local STACK_NAME=$1
  local PUT_MODE=$2
  local REGION=$3
  local EXIT_STATUS=$4

  shift 3
  local OUTPUT=$*

  if [[ ${EXIT_STATUS} -ne 0 ]]; then
    echo "The request to ${PUT_MODE} the stack was not accepted by AWS." 1>&2
    echo ${OUTPUT} 1>&2
    return 1
  fi

  echo "The request to ${PUT_MODE} the '${STACK_NAME}' stack was accepted by AWS."
  echo "View the stack's status at https://${REGION}.console.aws.amazon.com/cloudformation/home?region=${REGION}#/stacks?filter=active"
  echo ${OUTPUT} | jq '.'
  return 0
}
