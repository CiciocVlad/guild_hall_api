#!/bin/bash
set -xe

# Delete the previous deployment directory as needed.
if [ -d /usr/local/src/awsdeploy ]; then
    rm -rf /usr/local/src/awsdeploy
fi

mkdir -p /usr/local/src/awsdeploy
