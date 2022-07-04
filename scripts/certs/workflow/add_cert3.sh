#!/usr/bin/env bash

cert_file="$1"
key_file="$2"

CERT_CONF="$(dirname "${BASH_SOURCE[0]}")"/cert-conf.cfg

if [ ! -f "$cert_file" ]; then

	cert_hostname="$3"

	# Generate proper self-signed SSL certificate with SAN field
	# SAN field is required for Chrome >=58; see:
	# <https://textslashplain.com/2017/03/10/chrome-deprecates-subject-cn-matching/>
	/usr/local/opt/openssl/bin/openssl \
		req \
		-newkey rsa:2048 \
		-sha256 \
		-x509 \
		-days 3650 \
		-nodes \
		-config <(cat "$CERT_CONF" | sed s/{hostname}/"$cert_hostname"/g) \
		-out "$cert_file" \
		-keyout "$key_file"

fi

# Add SSL certificate to macOS Keychain as a trusted certificate
sudo security \
	add-trusted-cert \
	-d \
	-k /Library/Keychains/System.keychain \
	"$cert_file"
