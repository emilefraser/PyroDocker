#!/bin/bash

# Source helper functions
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/digicert-library.sh"

set -e

# Print usage
if [ $# -lt 1 ]; then
    echo "Not enough arguments provided!"
    echo "This script gets the redirector URL for an AP identified by the provided MAC address."
    echo "Usage: $0 <mac-address>"
    echo "mac-address - the primary MAC address of your AP device"
    exit 1
fi

mac="$(normalize_mac "$1")"

device_details=$(curl \
  --silent \
  --request GET "${DIGICERT_BASE_URL}v2/device?limit=1&device_identifier=${mac}" \
  --header "x-api-key: $DIGICERT_API_KEY" | jq --raw-output .records[0])

current_fields=$(echo "$device_details" | jq --raw-output .fields)

echo "$current_fields" | jq --raw-output '.[] | select( .name == "Redirector" ) | .value'
