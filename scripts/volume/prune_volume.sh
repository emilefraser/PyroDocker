#!/bin/bash

# see: https://github.com/chadoe/docker-cleanup-volumes
echo "Removing dangling volumes"
#docker volume rm $(docker volume ls -qf dangling=true)
docker volume ls -qf dangling=true | xargs -r docker volume rm

# Remove dangling volumes
echo "Removing volumes:" >&2
docker volume prune -f | sed '/Total reclaimed space/d'

echo "Done"
