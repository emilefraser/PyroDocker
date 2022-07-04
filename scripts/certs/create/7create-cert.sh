#!/bin/bash

#Now we run the command to create the certificate:
# using our CSR, the CA private key, the CA certificate, and the config file:

openssl x509 -req -in hellfish.test.csr -CA myCA.pem -CAkey myCA.key \
-CAcreateserial -out hellfish.test.crt -days 825 -sha256 -extfile hellfish.test.ext


# We now have three files: hellfish.test.key (the private key), hellfish.test.csr (the certificate signing request, or csr file), 
# and hellfish.test.crt (the signed certificate). We can configure local web servers to use HTTPS with the private key and the signed certificate.
