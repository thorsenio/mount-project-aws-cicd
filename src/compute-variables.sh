#!/usr/bin/env bash

# This script gets the values of regional and project-specific variables and uses them to generate
# default values for other variables.

# Change to the script's directory so that the variables files can be located by relative path,
# then switch back after the variables files have been sourced
  THIS_SCRIPT_DIR=$(dirname $(realpath ${PWD}/${BASH_SOURCE[0]}))
  cd ${THIS_SCRIPT_DIR} > /dev/null
  source ./functions.sh
  [[ -f ./config/global-variables.sh ]] && source ./config/global-variables.sh
  [[ -f ./config/regional-variables.sh ]] && source ./config/regional-variables.sh
  source ./config/project-variables.sh
  cd - > /dev/null

# Backward-compatibility for projects that use `PROFILE` instead of `Profile`
Profile=${Profile:=${PROFILE}}
PROFILE=${Profile}

# Verify that all required variables have values
for SETTING_NAME in \
    COMMIT_HASH \
    PLATFORM_COMMIT_HASH \
    PLATFORM_NAME \
    PLATFORM_VERSION \
    PLATFORM_VERSION_LABEL \
    PLATFORM_VERSION_STAGE \
    VERSION_STAGE \
    Profile \
    Region \
    ProjectDomainName \
    ProjectVersion; do
  if [[ -z ${!SETTING_NAME} ]]; then
    echo -e "No value is set for ${SETTING_NAME}\nAborting." 1>&2
    exit 1
  fi
done

# AWS constants
AWS_FREE_TIER_INSTANCE_TYPE='t2.micro'

# -- Platform descriptors
# The Dockerfile stores the `PLATFORM_*` values in environment variables
PlatformCommitHash=${PLATFORM_COMMIT_HASH:0:7}
PlatformName=${PLATFORM_NAME}
PlatformVersion=${PLATFORM_VERSION}
PlatformVersionLabel=${PLATFORM_VERSION_LABEL}
PlatformVersionStage=${PLATFORM_VERSION_STAGE}
PlatformMajorVersion=$(echo ${PlatformVersion} | head -n 1 | cut -d . -f 1)

if [[ ${PlatformVersionStage} == 'master' ]]; then
  PlatformId="${PlatformName}-v${PlatformMajorVersion}"
else
  PlatformId="${PlatformName}-v${PlatformMajorVersion}${PlatformVersionStage}"
fi

GlobalPlatformStackName="${PlatformId}-global"
RegionalPlatformStackName="${PlatformId}-regional"

# -- Project descriptors
# The values of `VERSION_STAGE` and `COMMIT_HASH` are set in the project mount script
ProjectVersionStage=${VERSION_STAGE}
ProjectVersionStage=${ProjectVersionStage//\//}
ProjectVersionStage=${ProjectVersionStage//-/}

# Combine project, version, and branch into values usable in the project
ProjectCommitHash=${COMMIT_HASH:0:7}
ProjectDescription="${ProjectDescription:=${ProjectName}}"
ProjectMajorVersion=$(echo ${ProjectVersion} | head -n 1 | cut -d . -f 1)

if [[ ${ProjectVersionStage} == 'master' ]]; then
  DeploymentId="${ProjectName}-v${ProjectMajorVersion}"
  ProjectVersionLabel=${ProjectVersion}
else
  DeploymentId="${ProjectName}-v${ProjectMajorVersion}${ProjectVersionStage}"
  ProjectVersionLabel="${ProjectVersion}-${ProjectVersionStage}"
fi

# ----- Domain names
NonproductionBaseDomainName=${NonproductionBaseDomainName:=${ProjectDomainName}}
if [[ ${ProjectVersionStage} == 'master' ]]; then
  SiteDomainName=${SiteDomainName:="www.${ProjectDomainName}"}
  CertifiedDomainName=${SiteDomainName}
else
  NonproductionDomainName=${NonproductionDomainName:=''}
  if [[ -n ${NonproductionDomainName} ]]; then
    # TODO: When a custom nonproduction domain name is specified, obtain a certificate for
    # that domain.
    SiteDomainName=${NonproductionDomainName}
    CertifiedDomainName=${NonproductionDomainName}
  else
    # Unless a custom NonproductionDomainName is specified, all nonproduction deployments are
    # expected to use this naming scheme.
    SiteDomainName="${DeploymentId,,}.${NonproductionBaseDomainName}"
    # Use a wildcard certificate.
    CertifiedDomainName="*.${NonproductionBaseDomainName}"
  fi
fi
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
EcsTasksServiceRoleName=${EcsTasksServiceRoleName:="ecs-tasks-service-role-${PlatformId}"}


# ----- Region-wide variables

# The S3 buckets below are referenced by the pipeline stack, but must be created independently if
# they do not already exist. Use `create-cicd-artifacts-bucket.sh`.
# AccountName is included in all bucket names to avoid name collisions

# Name of the S3 bucket that holds CloudFormation templates for the region. It is part of the
# regional platform stack
CfnTemplatesBucketName="${CfnTemplatesBucketName:=cfn-templates-${AccountName}-${PlatformId}}"

# Name of the S3 bucket that hosts CodeBuild & CodePipeline artifacts for all projects in the region
# Here CodeBuild & CodePipeline share the same bucket
CicdArtifactsBucketName="${CicdArtifactsBucketName:=cicd-artifacts-${AccountName}-${PlatformId}-${Region//-/}}"


# ----- Cluster-wide variables
Ec2InstanceType="${Ec2InstanceType:=${AWS_FREE_TIER_INSTANCE_TYPE}}"

# If the project specifies a cluster, it will be used; otherwise, the project gets its own cluster
EcsClusterName="${EcsClusterName:=${DeploymentId}-ecs-cluster}"

# These resources are shared by the cluster, so there should be only one of each
Ec2InstanceName="${Ec2InstanceName:=${EcsClusterName}-instance}"
EcsClusterStackName="${EcsClusterStackName:=${EcsClusterName}}"
EcsClusterVpcName="${EcsClusterVpcName:=${EcsClusterName}-vpc}"
EcsHealthCheckPath="${EcsHealthCheckPath:='/health'}"
JumpHostName="${JumpHostName:=${EcsClusterName}-jump-host}"
JumpHostStackName="${JumpHostStackName:=${JumpHostName}}"
KeyPairKeyName="${KeyPairKeyName:=${AccountName}-${Region//-/}-${EcsClusterName}}"

# TODO: Build in support for per-project subnets
VpcName="${VpcName:=${DeploymentId}-vpc}"
VpcDefaultSecurityGroupName="${VpcDefaultSecurityGroupName:=${VpcName}-sg}"
VpcStackName="${VpcStackName:=${VpcName}}"

FileSystemName="${FileSystemName:=${EcsClusterName}-fs}"
FileSystemStackName="${FileSystemStackName:=${FileSystemName}}"


# ----- Project-wide variables

# --- CodeBuild project
CodeBuildEnvironmentImage="${CodeBuildEnvironmentImage:='aws/codebuild/docker:18.09.0'}"
CodeBuildProjectName="${CodeBuildProjectName:=${DeploymentId}-cb-project}"
CodeBuildProjectStackName="${CodeBuildProjectStackName:=${CodeBuildProjectName}}"

# Name of the service role & policy used by CodeBuild to call AWS services for this project
CodeBuildServiceRoleName=${CodeBuildServiceRoleName:="${DeploymentId}-${Region//-/}-cb-service-role"}

# --- CodePipeline pipeline
CodePipelineName="${CodePipelineName:=${DeploymentId}-cp}"
CodePipelineStackName="${CodePipelineStackName:=${CodePipelineName}}"

# --- ECR repositories
EcrRepoNames=${EcrRepoNames:-''}

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

# CloudFront distribution
CloudfrontDistributionStackName="${CloudfrontDistributionStackName:=${DeploymentId}-cdn}"

# The name and stack of the S3 bucket that hosts the project's static files
ProjectBucketName="${ProjectBucketName:=${DeploymentId,,}-${Region//-/}-site}"
ProjectBucketStackName="${ProjectBucketStackName:=${ProjectBucketName}}"

# Name of the index and error documents for the site (for an SPA, these are typically the same)
if [[ ! -v SiteIndexDocument ]]; then
  SiteIndexDocument='index.html'
fi
SiteErrorDocument="${SiteErrorDocument:=${SiteIndexDocument}}"

S3SiteStackName="${S3SiteStackName:=${DeploymentId}-s3-site}"

# ECS-hosted site
#StaticFilesPathPattern="${StaticFilesPathPattern}:='/static/*'" # not yet implemented
