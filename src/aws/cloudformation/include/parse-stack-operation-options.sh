#!/usr/bin/env bash

# This script parses the arguments received by a CloudFormation stack script and sets
# variables accordingly; `source` this file from the script that uses it.

# Initialize arguments
WAIT=false

# Parse arguments
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
