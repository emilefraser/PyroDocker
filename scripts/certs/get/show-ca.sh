#!/bin/sh
ca_cert=${1}

openssl x509 -in $ca_cert -text -noout
