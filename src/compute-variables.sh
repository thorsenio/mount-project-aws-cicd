#!/usr/bin/env bash

# This script gets the values of regional and project-specific variables and uses them to generate
# default values for other variables.

# Change to the script's directory so that the variables files can be located by relative path,
# then switch back after the variables files have been sourced
THIS_SCRIPT_DIR=$(dirname $(realpath ${PWD}/${BASH_SOURCE[0]}))
cd ${THIS_SCRIPT_DIR} > /dev/null
source ./config/regional-variables.sh
source ./config/project-variables.sh
cd - > /dev/null

# ----- Dummy values for required variables
# TODO: Verify that all required values exist
SiteDomainName=${SiteDomainName:='www.example.com'}


# ----- Computed regional variables

# The S3 buckets below are referenced by the pipeline stack, but must be created independently
# if they do not already exist

# Name of the S3 bucket that hosts CodeBuild artifacts for all projects in the region
CodeBuildArtifactBucketName="${CodeBuildArtifactBucketName:=cicd-artifacts-${AccountName}-${Region}}"

# Name of the S3 bucket that hosts CodePipeline artifacts for all pipelines in the region
CodePipelineArtifactBucketName="${CodePipelineArtifactBucketName:=cicd-artifacts-${AccountName}-${Region}}"

# Name of the S3 bucket that holds CloudFormation templates for the region
TemplateBucketName="${TemplateBucketName:=cf-templates-${AccountName}-${Region//-/}}"


# ----- Computed cluster variables for the project
# If the project specifies a cluster, it will be used; otherwise, the project gets its own cluster
EcsClusterName="${EcsClusterName:-${ProjectName}-cluster}"

# These resources are shared by the cluster, so there should be only one of each
BastionInstanceName="${BastionInstanceName:=${EcsClusterName}-bastion}"
BastionStackName="${BastionStackName:=${EcsClusterName}-bastion-stack}"
EcsStackName="${EcsStackName:=${EcsClusterName}-stack}"
KeyPairKeyName="${KeyPairKeyName:=${EcsClusterName}-${Region//-/}}"

# TODO: Build in support for per-project subnets
VpcDefaultSecurityGroupName="${VpcDefaultSecurityGroupName:=${EcsClusterName}-sg}"
VpcStackName="${VpcStackName:=${EcsClusterName}-vpc-stack}"

# ----- Other computed project variables

# --- CodeBuild project
CodeBuildProjectName="${CodeBuildProjectName:=${ProjectName}-codebuild-project}"
CodeBuildProjectStackName="${CodeBuildProjectStackName:=${CodeBuildProjectName}-stack}"

# --- CodeCommit repo
RepoName="${RepoName:=${ProjectName}}"

# --- S3 site

# Replace `.` with `-` to make a valid stack name
SiteStackName="${SiteStackName:=${SiteDomainName//./-}-s3-site-stack}"

# The name of the S3 bucket that hosts the website files
BucketRandomSuffix=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 13 | head -n 1)
SiteBucketName="${SiteBucketName:=${SiteDomainName}-${BucketRandomSuffix}}"

# This stack name is ignored if the S3 bucket stack is created as a nested stack
SiteBucketStackName="${SiteBucketStackName:=${SiteBucketName//./-}-bucket-stack}"

# Name of the index and error documents for the site (for an SPA, these are typically the same)
SiteIndexDocument="${SiteIndexDocument:='index.html'}"
SiteErrorDocument="${SiteErrorDocument:=${SiteIndexDocument}}"

# --- CloudFront distribution

# This name is ignored if the CloudFront distribution stack is created as a nested stack
CloudfrontDistributionStackName="${CloudfrontDistributionStackName:=${ProjectName}-cdn-stack}"
