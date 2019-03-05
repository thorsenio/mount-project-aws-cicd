#!/usr/bin/env bash

# The values in this file overwrite the values declared in
# - `global-variables.sh`
# - `regional-variables.sh`
# and the defaults computed in `compute-variables.sh`

# Name of the project. This value is used to generate names for some of this project's resources
ProjectName='my-project'
ProjectDescription='My project'

ProjectDomain='example.com'
SiteDomain="www.${ProjectDomain}"

RepoName=${ProjectName}
RepoDescription="${ProjectDescription}"

ProjectVersion='0.1.0'
CodeBuildEnvironmentImage='aws/codebuild/nodejs:10.14.1'
# Other common images:
#aws/codebuild/docker:18.09.0
#aws/codebuild/docker:17.09.0
#aws/codebuild/nodejs:8.11.0
#aws/codebuild/python:3.7.1
#
# Full list: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
