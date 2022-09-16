#!/bin/sh

set -e

DOCKER_DIRECTORY="scripts"

# move into app directory
cd $(cd "$(dirname "$0")"; pwd) && cd ../$DOCKER_DIRECTORY

# Accepts as arguments docker-compose arguments except -p and -l as those are used already
docker compose -p local -f docker-compose-local-images.yml $@
