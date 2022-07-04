docker ps | grep frontend | cut -d' ' -f1
# or
docker ps | grep frontend | awk '{ print $1 }'