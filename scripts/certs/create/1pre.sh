#!/bin/bash

mkdir ~/certs
cd ~/certs

openssl genrsa -des3 -out myCA.key 2048

#oGenerating RSA private key, 2048 bit long modulus
#,.................................................................+++
#.....................................+++
#e is 65537 (0x10001)
#,Enter pass phrase for myCA.key:
#Verifying - Enter pass phrase for myCA.key:


openssl req -x509 -new -nodes -key myCA.key -sha256 -days 1825 -out myCA.pem


#Enter pass phrase for myCA.key:
#You are about to be asked to enter information that will be incorporated
#,into your certificate request.
#What you are about to enter is what is called a Distinguished Name or a DN.
#,There are quite a few fields but you can leave some blank
#For some fields there will be a default value,
#If you enter '.', the field will be left blank.
#-----
#Country Name (2 letter code) [AU]:US
#State or Province Name (full name) [Some-State]: Springfield State
#Locality Name (eg, city) []:Springfield
#Organization Name (eg, company) [Internet Widgits Pty Ltd]:Hellfish Media
#Organizational Unit Name (eg, section) []:7G
#Common Name (e.g. server FQDN or YOUR name) []:Hellfish Media
#Email Address []:abraham@hellfish.media

