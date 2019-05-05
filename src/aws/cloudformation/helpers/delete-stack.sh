#!/usr/bin/env bash

# This script deletes the specified stack in the project's region

if [[ $# -lt 1 || $# -gt 3 ]]
then
  echo "Usage: $0 STACK_NAME [REGION]" 1>&2
  exit 1
fi

STACK_NAME=$1
shift

if [[ $# -ne 0 ]]; then
  if [[ ! ${1:0:2} == '--' ]]; then
    REGION=$2
    shift
  fi
fi

# Parse arguments
## Initialize arguments
WAIT=false

## Parse optional arguments
while :; do
  case $1 in
    # Handle known options
    --wait) WAIT=true ;;

    # End of known options
    --) shift ; break ;;

    # Handle unknown options
    -?*) printf 'WARNING: Unknown option (ignored): %s\n' "$1" 1>&2 ;;

    # No more options
    *) break
  esac
  shift
done

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../aws-functions.sh
source ../../../compute-variables.sh

REGION=${REGION:-${Region}}

echo "Requesting deletion of the '${STACK_NAME}' stack..."
OUTPUT=$(aws cloudformation delete-stack \
  --profile ${Profile} \
  --region ${REGION} \
  --stack-name ${STACK_NAME} \
)

echoPutStackOutput ${STACK_NAME} delete ${REGION} $? ${OUTPUT}
exitOnError $?

if [[ ${WAIT} == true ]]; then
  awaitStackOperationComplete ${Profile} ${Region} delete ${STACK_NAME}
  exitOnError $?
fi
