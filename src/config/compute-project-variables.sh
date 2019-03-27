#!/usr/bin/env bash

# `source` this script to access values by `compute-variables.sh`
# Requires aws-cicd >= v0.12

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

THIS_SCRIPT_DIR=$(dirname $(realpath ${PWD}/${BASH_SOURCE[0]}))
cd ${THIS_SCRIPT_DIR} > /dev/null
source /var/lib/functions.sh
source /var/lib/aws/aws-functions.sh
source /var/lib/compute-variables.sh
cd - > /dev/null

# Custom project variables
# Here you can define here any variables that use the values generated by the platform