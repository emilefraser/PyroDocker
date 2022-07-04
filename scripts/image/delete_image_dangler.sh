#!/bin/bash -
#===============================================================================
#
#          FILE: delete_image_dangler.sh
#
#         USAGE: ./delete_image_dangler.sh
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (),
#  ORGANIZATION:
#       CREATED: 05/06/2022 22:31
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
for v in $(sudo docker volume ls -qf 'dangling=true'); do sudo docker volume rm "$v"; done

