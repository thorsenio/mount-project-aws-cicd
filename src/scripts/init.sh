#!/usr/bin/env bash

# This script prepares a project to use the AWS CI/CD pipeline

# Change to the directory of this script so that relative paths resolve correctly
cd $(dirname "$0")

# Copy config files so they can be used as templates
cp -v -i /var/lib/config-templates/*.sh /var/project/config/
