#!/bin/sh
set -e

docker build -t crafting-guild-hall-release-machine . --file=Dockerfile --network=host && docker run --network "host" -v $(pwd):/opt/crafting/guildhall -it crafting-guild-hall-release-machine
