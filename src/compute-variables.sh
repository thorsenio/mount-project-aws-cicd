#!/usr/bin/env bash

# This script gets the values of regional and project-specific variables and uses them to generate
# default values for other variables.

# Change to the script's directory so that the variables files can be located by relative path,
# then switch back after the variables files have been sourced
THIS_SCRIPT_DIR=$(dirname $(realpath ${PWD}/${BASH_SOURCE[0]}))
cd ${THIS_SCRIPT_DIR} > /dev/null
source ./config/global-variables.sh
source ./config/regional-variables.sh
source ./config/project-variables.sh
cd - > /dev/null

# TODO: Verify that all required values exist

# Platform deployment ID
# The Dockerfile sets `PLATFORM_NAME`, `PLATFORM_VERSION` & `PLATFORM_VERSION_POSTFIX` as env vars
PlatformName=${PLATFORM_NAME:='aws-cicd'}
PlatformVersion=${PLATFORM_VERSION:='1.0.0'}
PlatformVersionPostfix=${PLATFORM_VERSION_POSTFIX:=''}
PlatformMajorVersion=$(echo ${PlatformVersion} | head -n 1 | cut -d . -f 1)
PlatformId="${PlatformName}-p${PlatformMajorVersion}${PlatformVersionPostfix}"
RegionalPlatformStackName="${PlatformId}-regional"
GlobalPlatformStackName="${PlatformId}-global"

# Application deployment ID
BranchName=${BranchName:='master'}
if [[ ${BranchName} == 'master' ]]
then
  VersionPostfix=''
else
  # Use a deployment name if provided; otherwise, use the branch name (converting `/` to `-`)
  VersionPostfix=${DeploymentName:=${BranchName//\//-}}
fi

# Project, version, and branch are combined into a value usable by the project
ProjectDescription="${ProjectDescription:=${ProjectName}}"
ProjectVersion="${ProjectVersion:=0.0.1}"
ProjectMajorVersion=$(echo ${ProjectVersion} | head -n 1 | cut -d . -f 1)
ProjectVersionBranch="${ProjectName}-v${ProjectMajorVersion}-${BranchName}"
DeploymentId="${ProjectName}-v${ProjectMajorVersion}${VersionPostfix}"

SiteDomainName=${SiteDomainName:='www.example.com'}
# TODO: FEATURE: Possibly add SiteUrl to allow for microservices hosted at the same domain
# TODO: FEATURE: Support multiple domain names
# TODO: FEATURE: Support URLs instead of domain names

# ----- Defaults
ProtectAgainstTermination='false'


# Note that stack names generated below are ignored when the stacks are created as nested stacks
# Typically, they are created independently of their parent only during testing & development

# ----- Account-wide variables

# Name and ARN of the service role used by CodePipeline to call AWS services
CodePipelineServiceRoleName=${CodePipelineServiceRoleName:="cp-service-role-${PlatformId}"}
CodePipelineServiceRoleArn="arn:aws:iam::${AccountNumber}:role/${CodePipelineServiceRoleName}"


# ----- Region-wide variables

# The S3 buckets below are referenced by the pipeline stack, but must be created independently if
# they do not already exist. Use `create-cicd-artifacts-bucket.sh`.
# AccountName is included in all bucket names to avoid name collisions

# Name of the S3 bucket that hosts CodeBuild & CodePipeline artifacts for all projects in the region
# Here CodeBuild & CodePipeline share the same bucket
CicdArtifactsBucketName="${CicdArtifactsBucketName:=cicd-artifacts-${AccountName}-${PlatformId}-${Region//-/}}"

# Name of the service role & policy used by CodeBuild to call AWS services for this project
CodeBuildServiceRoleName=${CodeBuildServiceRoleName:="cb-service-role-${PlatformId}-${Region//-/}"}
CodeBuildServiceRolePolicyName=${CodeBuildServiceRolePolicyName:="cb-service-role-policy-${PlatformId}-${Region//-/}"}

# Name of the S3 bucket that holds CloudFormation templates for the region. It is part of the
# regional platform stack
CfTemplatesBucketName="${CfTemplatesBucketName:=cf-templates-${AccountName}-${PlatformId}-${Region//-/}}"


# ----- Cluster-wide variables

# If the project specifies a cluster, it will be used; otherwise, the project gets its own cluster
EcsClusterName="${EcsClusterName:=${DeploymentId}-cluster}"

# These resources are shared by the cluster, so there should be only one of each
BastionInstanceName="${BastionInstanceName:=${EcsClusterName}-bastion}"
BastionStackName="${BastionStackName:=${BastionInstanceName}}"
EcsClusterStackName="${EcsClusterStackName:=${EcsClusterName}}"
KeyPairKeyName="${KeyPairKeyName:=${EcsClusterName}-${Region//-/}}"
EcsClusterVpcName="${VpcName:=${EcsClusterName}-vpc}"

# TODO: Build in support for per-project subnets
VpcName="${VpcName:=${DeploymentId}-vpc}"
VpcStackName="${VpcStackName:=${VpcName}}"
VpcDefaultSecurityGroupName="${VpcDefaultSecurityGroupName:=${VpcName}-sg}"

# ----- Project-wide variables

# --- CodeBuild project
CodeBuildProjectName="${CodeBuildProjectName:=${DeploymentId}-cb-project}"
CodeBuildProjectStackName="${CodeBuildProjectStackName:=${CodeBuildProjectName}}"
CodeBuildEnvironmentImage="${CodeBuildEnvironmentImage:='aws/codebuild/docker:18.09.0'}"

# --- CodePipeline pipeline
CodePipelineName="${CodePipelineName:=${DeploymentId}-cp}"
CodePipelineStackName="${CodePipelineStackName:=${CodePipelineName}}"

# --- Events rule
EventsRuleRandomId=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9-' | fold -w 24 | head -n 1)

# These values are used only when the rule is created independently of its parent stack
# (i.e., probably only during testing & development)
EventsRepoChangeRuleName="${EventsRepoChangeRuleName:=${CodePipelineName}-events-repochangerule}"
EventsRepoChangeRuleStackName="${EventsRepoChangeRuleStackName:=${EventsRepoChangeRuleName}}"

# --- CodeCommit repo
RepoName="${RepoName:=${ProjectName}}"
RepoDescription="${RepoDescription:=${ProjectDescription}}"

# --- Website stacks

SiteStackName="${SiteStackName:=${DeploymentId}-site}"

# The name and stack of the S3 bucket that hosts the project's static files
ProjectBucketName="${ProjectBucketName:=${DeploymentId}-bucket}"
ProjectBucketStackName="${ProjectBucketStackName:=${ProjectBucketName}}"

# Name of the index and error documents for the site (for an SPA, these are typically the same)
SiteIndexDocument="${SiteIndexDocument:='index.html'}"
SiteErrorDocument="${SiteErrorDocument:=${SiteIndexDocument}}"

# --- CloudFront distribution
CloudfrontDistributionStackName="${CloudfrontDistributionStackName:=${DeploymentId}-cdn}"
