#!/usr/bin/env bash

# This script is meant for port forwarding to a host with a private IP address (the private host)
# via a host with a public IP address (the jump host).
#
# Typical use case:
# - the private host is in a private subnet of a VPC
# - the jump host is in a public subnet of the same VPC
# - the local host is not in the VPC
#
# Assumptions:
# - the identity (.pem) file is assumed to be the same for the private host and the jump host
# - the port on the private host is mapped to the same port on the local host

# Usage:
#   forward-via-jump-host.sh PORT PRIVATE_HOST JUMP_HOST IDENTITY_FILE

# Check parameters
if [[ $# -lt 4 ]]
then
  echo 'Usage: forward-via-jump-host.sh PORT PRIVATE_HOST JUMP_HOST IDENTITY_FILE'
  exit 1
fi

PORT=$1
PRIVATE_HOST=$2
JUMP_HOST=$3
IDENTITY_FILE=$4

ssh -i ${IDENTITY_FILE} \
  -o "proxycommand ssh -W %h:%p -i ${IDENTITY_FILE} ec2-user@${JUMP_HOST}" \
  -NT -L ${PORT}:localhost:${PORT} \
  ec2-user@${PRIVATE_HOST}
