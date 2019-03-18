#!/usr/bin/env bash

# This script restarts all tasks in the service that has the same name as the deployment.
# As such, it is intended for use with the ECS site stack, and will need modification if it is
# to be used to restart tasks in an arbitrary service.

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

source ../../compute-variables.sh

aws ecs update-service \
  --profile ${Profile} \
  --region ${Region} \
  --cluster ${EcsClusterName} \
  --force-new-deployment \
  --service ${DeploymentId}
