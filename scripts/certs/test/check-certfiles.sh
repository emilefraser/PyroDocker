openssl req -text -noout -verify -in csr.pem /n openssl rsa -in my.key -check /n openssl pkcs12 -info -in keystore.p12
