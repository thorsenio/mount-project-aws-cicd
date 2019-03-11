#!/usr/bin/env bash

# This script is meant for connecting to a host with a private IP address (the private host)
# via a host with a public IP address (the bastion host).
#
# Typical use case:
# - the private host is in a private subnet of a VPC
# - the bastion host is in a public subnet of the same VPC
# - the connection is made from outside the private subnet
#
# The identity (.pem) file is assumed to be the same for the private host and the bastion host.

# Usage:
#   ssh-via-bastion.sh PRIVATE_HOST BASTION_HOST IDENTITY_FILE

# Check parameters
if [[ ${#} -lt 3 ]]
then
  echo 'Usage: ssh-via-bastion.sh PRIVATE_HOST BASTION_HOST IDENTITY_FILE'
  exit 1
fi

PRIVATE_HOST=${1}
BASTION_HOST=${2}
IDENTITY_FILE=${3}

ssh -i ${IDENTITY_FILE} \
  -o "proxycommand ssh -W %h:%p -i ${IDENTITY_FILE} ec2-user@${BASTION_HOST}" \
  ec2-user@${PRIVATE_HOST}
