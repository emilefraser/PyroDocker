#!/bin/bash

echo -e "Docker Summary\n"
echo "Containers:"

containers=$(docker ps --filter status=running --format='{{.Names}}')

bc=$containers | sort
echo $bc

