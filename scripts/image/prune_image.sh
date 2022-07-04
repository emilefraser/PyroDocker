# Remove unused images
docker image prune

docker images | tail -n +2 | awk '$1 == "<none>" {print $'$1'}'

# see: http://stackoverflow.com/questions/32723111/how-to-remove-old-and-unused-docker-images
docker images
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)

docker images | grep "none"
docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')

# delte untagged images
docker rmi $(docker images | grep "<none>" | awk '{print $3}')

# see: http://stackoverflow.com/questions/32723111/how-to-remove-old-and-unused-docker-images
docker ps
docker ps -a
docker rm $(docker ps -qa --no-trunc --filter "status=exited")
