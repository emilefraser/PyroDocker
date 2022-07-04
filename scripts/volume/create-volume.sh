#!/bin/bash
sudo docker run -it -v geeksforgeeks:/shared-volume --name my-container-01 ubuntu
docker volume create --driver nas --name nfs-storage
docker volume create --driver local \
      --opt type=none \
      --opt device=/home/user/test \
      --opt o=bind \
      test_vol:
