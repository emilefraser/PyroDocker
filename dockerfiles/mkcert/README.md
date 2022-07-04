# A docker image for mkcert.dev

mkcert.dev is a tool for developer to generate valid certificates.
Those certificates can then be used in their dev environment.

This repository provides a dockerfile and a helper script to:

- Create CA certificate
- Create a server certificate (key + crt)
- Create a server certificate (p12)
- Convert the server certificate to JKS format
- Convert the CA certificate to JKS format

## Usage

```sh
docker run -v /tmp/certs:/certs -e SERVER_HOSTNAMES="localhost.localdomain localhost" -it nmasse/mkcert:latest
```

```
$ ls -l /tmp/certs/
total 64
-rw-r--r--  1 nmasse  wheel  4839 Mar 26 10:58 keystore.jks
-r--------  1 nmasse  wheel  2484 Mar 26 10:58 rootCA-key.pem
-rw-r--r--  1 nmasse  wheel  1639 Mar 26 10:58 rootCA.pem
-rw-r--r--  1 nmasse  wheel  1517 Mar 26 10:58 server.crt
-rw-------  1 nmasse  wheel  1704 Mar 26 10:58 server.key
-rw-r--r--  1 nmasse  wheel  3927 Mar 26 10:58 server.p12
-rw-r--r--  1 nmasse  wheel  1466 Mar 26 10:58 truststore.jks

$ openssl x509 -noout -text -in /tmp/certs/server.crt |grep -A1 'X509v3 Subject Alternative Name'
            X509v3 Subject Alternative Name: 
                DNS:localhost.localdomain, DNS:localhost
```

## Environment variables

**SERVER_HOSTNAMES**

- the hostnames to include in the certificate (list of hostnames separated by a space)
- default value: `docker.for.mac.localhost docker.for.win.localhost localhost localhost.localdomain`

**JKS_PASSWORD**

- the password used to protect the JKS store and keys
- default value: `super-secret`

**Note:** the password protecting the PKCS#12 is hardcoded to `changeit` !
