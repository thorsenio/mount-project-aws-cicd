#!/usr/bin/env bash

# This script deletes the S3 bucket stack created by `put-s3-site-bucket-stack.sh`

# Typically, this script should be used only to test the template. Ordinarily, the bucket stack
# is created & deleted as a nested stack within the S3 site stack.

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

./delete-s3-asset-bucket-stack.sh
