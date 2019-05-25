#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source variables.sh

docker push ${IMAGE_BASE_NAME}
docker push ${IMAGE_BASE_NAME}:${VERSION}
