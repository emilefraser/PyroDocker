#!/bin/bash

docker network ls  
docker network ls | grep "bridge"   
docker network rm $(docker network ls | grep "bridge" | awk '/ / { print $1 }')
