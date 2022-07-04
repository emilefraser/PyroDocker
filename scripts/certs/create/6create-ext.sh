#!/bin/bash

echo "authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = 192.168.68.120
DNS.3 = portainer.docker.local
DNS.4 = *.docker.local" > hellfish.test.ext
