#!/usr/bin/env bash

# Change to the directory of this script
cd $(dirname "$0")

for TEMPLATE in \
  'cloudfront-distribution.yml' \
  'codebuild-project.yml' \
  'codepipeline.yml' \
  'codepipeline-service-role.yml' \
  'ecs-stack.yml' \
  'bastion.yml' \
  'events-repo-change-rule.yml' \
  's3-site.yml' \
  'site-bucket.yml' \
  'vpc-stack.yml' \
; do
  ./validate-template.sh "templates/${TEMPLATE}"
done
