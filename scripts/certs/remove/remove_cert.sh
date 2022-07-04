#!/usr/bin/env bash

cert_file="$1"
key_file="$2"

if [ ! -f "$cert_file" ]; then
	>&2 echo "Certificate file does not exist"
	exit
fi

cert_fingerprint="$(openssl x509 \
	-noout \
	-fingerprint \
	-sha1 \
	-inform pem \
	-in "$cert_file" \
	| cut -d '=' -f 2 \
	| grep -o '[0-9A-F]' \
	| xargs \
	| tr -d ' ')"

sudo security \
	delete-certificate \
	-Z "$cert_fingerprint" \
	/Library/Keychains/System.keychain

# Keychain errors don't output trailing newlines; output one to reclaim
# readability
if [ $? != 0 ]; then
	echo ''
fi

rm -f "$cert_file"
rm -f "$key_file"
