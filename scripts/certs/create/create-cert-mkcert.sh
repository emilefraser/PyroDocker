#!/bin/bash

#mkcert portainer localhost 192.168.68.120 ::1 portainer.docker.local

mkcert -key-file portainer.pem -cert-file portainer.pem localhost 192.168.68.120 ::1 portainer.docker.local

