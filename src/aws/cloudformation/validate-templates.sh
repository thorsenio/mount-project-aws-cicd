#!/usr/bin/env bash

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

for TEMPLATE in \
  'codebuild-project.yml' \
  'codepipeline.yml' \
  'codepipeline-service-role.yml' \
  'ecs-cluster.yml' \
  'events-repo-change-rule.yml' \
  'global-platform.yml' \
  'jump-host.yml' \
  'regional-platform.yml' \
  's3-cloudfront-distribution.yml' \
  's3-site.yml' \
  's3-asset-bucket.yml' \
  's3-site-bucket.yml' \
  'vpc.yml' \
; do
  ./validate-template.sh "templates/${TEMPLATE}"
done
