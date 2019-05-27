#!/usr/bin/env bash

# This file contains functions unrelated to AWS

# Constants for formatting console output
FONT_WEIGHT_BOLD=$(tput bold)
FONT_WEIGHT_NORMAL=$(tput sgr0)


# Given an argument, exit with status code
#   0 if the argument isn't empty
#   1 if the argument is empty
assertNotEmpty () {
  if [[ $# -eq 0 || -z "$1" ]]
  then
    echo "Assertion failed" 1>&2
    false
  fi
  true
}


# Given a Git branch name, make it safe for use as a text fragment in AWS resource names
branchNameToVersionStage () {
  local BRANCH_NAME=$1

  # Convert branch name to lowercase and strip `\` and `-`
  VERSION_STAGE=$(echo ${BRANCH_NAME} | tr '[:upper:]' '[:lower:]')
  VERSION_STAGE=${VERSION_STAGE//\//}
  VERSION_STAGE=${VERSION_STAGE//-/}
  echo ${VERSION_STAGE}
}


# Return 0 if the Docker image exists locally; otherwise, return 1
dockerLocalImageExists () {
  local TAG=$1
  if [[ "$(docker image ls --quiet ${TAG} 2> /dev/null)" == '' ]]; then
    return 1
  fi
  return 0
}


dockerUseLocalImageOrPull () {
  local IMAGE_TAG=$1

  if dockerLocalImageExists ${IMAGE_TAG}; then
    echo "Using local Docker image '${IMAGE_TAG}'"
  else
    echo "The '${IMAGE_TAG}' image was not found locally. Pulling from Docker Hub ..."
    docker pull ${IMAGE_TAG}
    return $?
  fi
}


# Given a domain name, echo the first two levels of the domain name
# Example: Given `any.subdomain.example.com`, echo `example.com`
echoApexDomain () {
  local DOMAIN_NAME=$1

  local DOMAIN_LEVEL_2=$(echo ${DOMAIN_NAME} | awk -F '.' '{ print $(NF-1) }')
  local DOMAIN_LEVEL_1=$(echo ${DOMAIN_NAME} | awk -F '.' '{ print $NF }')
  echo "${DOMAIN_LEVEL_2}.${DOMAIN_LEVEL_1}"
}

# Echo a hash of a concatenated data string, today's date, and an attempt number.
# The hash changes only when the date changes.
# TODO: MAYBE: Warn about a recent date change to guard against situations where the token
#  changes because the date has changed between attempts?
echoDailyIdempotencyToken () {
  local DATA=$1
  local ATTEMPT_NUMBER=$2

  local DATE_STRING=$(date -I)
  local IDEMPOTENCY_TOKEN=$(printf "${DATA} ${DATE_STRING} ${ATTEMPT_NUMBER}" | md5sum | cut -d ' ' -f 1)

  echo ${IDEMPOTENCY_TOKEN}
}

echoFqdn () {
  local DOMAIN_NAME=$1

  # If the terminating period is missing, add it to get a fully qualified domain name
  if [[ "${DOMAIN_NAME: -1}" == '.' ]]; then
    echo ${DOMAIN_NAME}
  else
    echo "${DOMAIN_NAME}."
  fi
}

echoRandomId () {
  local LENGTH=$1
  LENGTH=${LENGTH:='13'}
  echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${LENGTH} | head -n 1)
}

echoRandomLowercaseId () {
  local LENGTH=$1
  LENGTH=${LENGTH:='13'}
  echo $(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w ${LENGTH} | head -n 1)
}

# Given 2 values, echo the greater of them
echoMax () {
  echo $(( $1 > $2 ? $1 : $2 ))
}

# Given 2 values, echo the lesser of them
echoMin () {
  echo $(( $1 < $2 ? $1 : $2 ))
}

# Given a domain name, remove the top 2 domains and return the result
echoSubdomains () {
  [[ $1 =~ ^(.+)(\.[^.]+)(\.[^.]+)$ ]]
  if [[ $? -ne 0 ]]; then
    echo ''
    exit 1
  fi
  echo ${BASH_REMATCH[1]}
}

embold () {
  local bold=$(tput bold)
  local normal=$(tput sgr0)

  local TEXT_TO_EMBOLD=$1
  echo "${bold}${TEXT_TO_EMBOLD}${normal}"
}

exitOnError () {
  local RETURN_CODE=$1
  local ERROR_MESSAGE=${2:-''}

  if [[ ${RETURN_CODE} -ne 0 ]]; then
    if [[ -n ${ERROR_MESSAGE} ]]; then
      echo -e "${ERROR_MESSAGE}\n" 1>&2
    fi
    exit 1
  fi
}


# TODO: Refactor versioning
generateVersionLabel () {
  local VERSION=$1
  local VERSION_STAGE=$2

  if [[ ${VERSION_STAGE} == 'master' ]]; then
    echo "${VERSION}"
  else
    echo "${VERSION}-${VERSION_STAGE}"
  fi
}


getGitBranchName () {
  git symbolic-ref --short HEAD
}


getGitCommitHash () {
  git rev-parse HEAD
}


gitRepoIsClean () {
  if [[ -z "$(git status --porcelain)" ]]; then
    return 0
  fi
  return 1
}


promptForVersionStage () {
  local VERSION_STAGE=$1
  local BRANCH_NAME
  local DEFAULT_VERSION_STAGE

  if [[ -n ${VERSION_STAGE} ]]; then
    # TODO: Instead of sanitizing the name, inform the user that it is invalid & exit
    VERSION_STAGE=$(branchNameToVersionStage ${VERSION_STAGE})
    echo ${VERSION_STAGE}
    return 0
  fi

  BRANCH_NAME=$(getGitBranchName)
  DEFAULT_VERSION_STAGE=$(branchNameToVersionStage ${BRANCH_NAME})

  read -p "Version stage: [${DEFAULT_VERSION_STAGE}] " VERSION_STAGE
  # TODO: Validate the entered text (should consist only of alphanumeric chars)
  if [[ -z ${VERSION_STAGE} ]]; then
    VERSION_STAGE=${DEFAULT_VERSION_STAGE}
  fi

  echo ${VERSION_STAGE}
}
