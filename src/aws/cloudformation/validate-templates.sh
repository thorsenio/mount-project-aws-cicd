#!/usr/bin/env bash

# Change to the directory of this script
cd $(dirname "$0")

for TEMPLATE in \
  'codebuild-project.yml' \
  'codepipeline.yml' \
  'codepipeline-service-role.yml' \
  'ecs-stack.yml' \
  'bastion-stack.yml' \
  'events-repo-change-rule.yml' \
  'vpc-stack.yml' \
; do
  ./validate-template.sh "templates/${TEMPLATE}"
done
