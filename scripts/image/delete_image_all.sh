# delete all images
# docker rmi $(docker images -q)
docker ps -q -a | xargs docker rm
