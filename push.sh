#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

# Include helper functions.
source src/functions.sh
if [[ $? -ne 0 ]]; then
  echo -e "The functions file could not be found. Aborting."
  exit 1
fi

# Handle arguments
# -- Handle options & arguments
if [[ $1 == '--help' || $1 == '-h' || $1 == '-\?' ]]; then
  showHelp
  exit 0
fi

if [[ $# -gt 1 ]]; then
  showHelp
  exit 1
fi

VERSION_STAGE=$(promptForVersionStage $1)

# Read this module's environment variables from file.
source variables.sh
if [[ $? -ne 0 ]]; then
  echo -e "The variables file could not be found. Aborting."
  exit 1
fi

VERSION_LABEL=$(generateVersionLabel ${PLATFORM_VERSION} ${VERSION_STAGE})

docker push ${IMAGE_BASE_NAME}:${PLATFORM_VERSION}
