# Delete all containers

```
$ docker ps -q -a | xargs docker rm
```

- -q prints only the container IDs
- -a prints all containers

Notice that it uses xargs to issue a remove container command for each container ID

# Delete images

## Delete all untagged images

```
$ docker rmi $(docker images | grep "<none>" | awk '{print $3}')
```

awk must use a single quote (this filters all image IDs)

## Delete all images
```
$ docker rmi $(docker images -q)
```

## Delete all dangling volumes

```
for v in $(sudo docker volume ls -qf 'dangling=true'); do sudo docker volume rm "$v"; done
```