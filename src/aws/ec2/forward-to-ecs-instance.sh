#!/usr/bin/env bash

# This script forwards a port from the local host via a bastion host to the same port of the
# nth-index cluster instance of the ECS stack.
#
# Example: To forward port 80 of the local host to port 80 of the 2nd container instance:
#
#   ```
#   forward-to-ecs-instance.sh 1 80
#   ```

if [[ ${#} -lt 2 ]]
then
  echo "Usage: ${0} INSTANCE_INDEX PORT" 1>&2
  exit 1
fi

INSTANCE_INDEX=${1}
PORT=${2}

# Change to the directory of this script
cd $(dirname "$0")

helpers/connect-via-bastion-to-ecs-instance.sh forward ${INSTANCE_INDEX} ${PORT}
