#!/usr/bin/env bash

# The values in this file overwrite the values declared in
# - `global-variables.sh`
# - `regional-variables.sh`
# and the defaults computed in `compute-variables.sh`

# Name of the project. This value is used to generate names for some of this project's resources
ProjectName='my-project'
ProjectDescription='My project'
ProjectDomain='example.com'
SiteDomainName='www.example.com'

RepoName=${ProjectName}
RepoDescription="${ProjectDescription}"

ProjectVersion='0.1.0'
