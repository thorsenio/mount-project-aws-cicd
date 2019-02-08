#!/usr/bin/env bash

# This script gets the values of regional and project-specific variables and uses them to generate
# default values for other variables.

# TODO: Don't compute a value if one is provided in one of the source files.

# Change to the script's directory so that the variables files can be located by relative path,
# then switch back after the variables files have been sourced
THIS_SCRIPT_DIR=$(dirname $(realpath ${PWD}/${BASH_SOURCE[0]}))
cd ${THIS_SCRIPT_DIR} > /dev/null
source ./config/regional-variables.sh
source ./config/project-variables.sh
cd - > /dev/null


# ----- Computed regional variables

# The S3 buckets below are referenced by the pipeline stack, but must be created independently
# (if they do not already exist)

# Name of the S3 bucket that holds CloudFormation templates for the region
TemplateBucketName="cf-templates-${AccountName}-${Region//-/}"


# ----- Computed cluster variables for the project
# If the project specifies a cluster, it will be used; otherwise, the project gets its own cluster
EcsClusterName="${EcsClusterName:-${ProjectName}-cluster}"

# These resources are shared by the cluster, so there should be only one of each
BastionInstanceName="${EcsClusterName}-bastion"
BastionStackName="${EcsClusterName}-bastion-stack"
EcsStackName="${EcsClusterName}-stack"
KeyPairKeyName="${EcsClusterName}-${Region//-/}"

# TODO: Build in support for per-project subnets
VpcDefaultSecurityGroupName="${EcsClusterName}-sg"
VpcStackName="${EcsClusterName}-vpc-stack"

# ----- Other computed project variables
