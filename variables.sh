#!/usr/bin/env bash

DOCKER_ACCOUNT_NAME=skypilot
PACKAGE_NAME=mount-project-aws-cicd
VERSION_STAGE='master'

PLATFORM_DIR=/var/lib/${PACKAGE_NAME}
PROJECT_DIR=/var/project

# shorter name used to generate AWS resource names
PLATFORM_NAME=aws-cicd
PLATFORM_VERSION=$(cat ./package.json | jq '.version' --raw-output)
IMAGE_BASE_NAME=${DOCKER_ACCOUNT_NAME}/${PACKAGE_NAME}
