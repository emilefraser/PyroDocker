openssl x509 -text -in my.pem
openssl x509 -in cert.pem -text -noout

openssl ca -text -in my-ca.pem 

openssl req -text -in csr.pem
openssl rsa -in key.pem -check noout
