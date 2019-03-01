#!/usr/bin/env bash

# Work in progress

# The values in this file
#   - overwrite the defaults computed in `compute-variables.sh`
#   - are overwritten by the values declared in
#     - `regional-variables.sh`
#     -  `project-variables.sh`

# These values are used as the defaults for this account. can be overridden by thin
# `regional-variable.sh` or `project-variables.sh`
AccountName='accountname'
AccountNumber='123456708901'

# Name of the IAM profile from which to get the credentials to be used by the AWS CLI
# (Recommended: use the account name as the profile name
PROFILE=${AccountName}

# This is used to generate domain names for deployments other than production
NonproductionBaseDomain='example.com'

# Example of generated name
#   ProjectDomain: myproject.com
#   ProjectName: myproj
#   ProjectVersion: 1.5.0
#   ProjectVersionStage: dev
# //=>
#   generated SiteDomain: myproj-v1dev.example.com
