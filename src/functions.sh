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

echoFqdn () {

  local DOMAIN_NAME=$1

  # If the terminating period is missing, add it to get a fully qualified domain name
  if [[ "${DOMAIN_NAME: -1}" == '.' ]]; then
    echo ${DOMAIN_NAME}
  else
    echo "${DOMAIN_NAME}."
  fi
}

embold () {
  local bold=$(tput bold)
  local normal=$(tput sgr0)

  local TEXT_TO_EMBOLD=$1
  echo "${bold}${TEXT_TO_EMBOLD}${normal}"
}

