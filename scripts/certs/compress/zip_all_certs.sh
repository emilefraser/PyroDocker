#!/bin/bash

# Source helper functions
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/digicert-library.sh"

archive_name=${1:-certificates}

zip -j -r "${archive_name}" "$GENERATED_DIR" -i "*.pem" "*.jks" "*.pkcs12"

