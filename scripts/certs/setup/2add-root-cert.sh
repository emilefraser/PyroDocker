#!/bin/bash

#ca-certificates package.
sudo apt-get install -y ca-certificates

#Copy the myCA.pem file to the /usr/local/share/ca-certificates directory as a myCA.crt file.
sudo cp ~/certs/myCA.pem /usr/local/share/ca-certificates/myCA.crt

#Update the certificate store.
sudo update-ca-certificates
