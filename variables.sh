#!/usr/bin/env bash

DOCKER_ACCOUNT_NAME='skypilot'
PACKAGE_NAME='mount-project-aws-cicd'
PLATFORM_NAME='aws-cicd' # shorter name used to generate AWS resource names

PLATFORM_DIR="/var/lib/${PACKAGE_NAME}"
PROJECT_DIR='/var/project'

# TODO: Read the version from `package.json`
VERSION='2.6.4'
VERSION_STAGE='master' # deprecated
