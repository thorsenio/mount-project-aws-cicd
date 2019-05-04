#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../config/compute-project-variables.sh

STACK_NAME=${FileSystemStackName}

helpers/delete-stack.sh ${STACK_NAME}
exitOnError $?
