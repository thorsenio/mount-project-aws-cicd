#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../config/compute-project-variables.sh

helpers/delete-stack.sh ${FileSystemStackName}
exitOnError $?
