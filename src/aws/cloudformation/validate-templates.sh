#!/usr/bin/env bash

# Change to the directory of this script
cd $(dirname "$0")

for TEMPLATE in \
  'ecs-stack.yml' \
  'bastion-stack.yml' \
  'vpc-stack.yml' \
; do
  ./validate-template.sh "templates/${TEMPLATE}"
done
