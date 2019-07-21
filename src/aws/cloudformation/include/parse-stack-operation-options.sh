#!/usr/bin/env bash

# This script parses the arguments received by a CloudFormation stack script and sets
# variables accordingly; `source` this file from the script that uses it.

# TODO: Disallow the use of `--dry-run` and `--wait` together

# Initialize arguments
WAIT=false
DRY_RUN=false

# Parse arguments
while :; do
  case $1 in
    # Handle known options
    --dry-run) DRY_RUN=true ;;

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
