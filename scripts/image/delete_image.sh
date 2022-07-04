# delete all images
docker rmi $(docker images -q)

# see: http://stackoverflow.com/questions/32723111/how-to-remove-old-and-unused-docker-images
$ docker images | grep "none"
$ docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')

# Remove untagged images
echo "Removing images:" >&2
untagged_images 3 | xargs --no-run-if-empty docker rmi
