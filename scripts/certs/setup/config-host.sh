#!/bin/bash

If you’re on Linux or Windows using Apache, you’ll need to enable the Apache SSL mod, 
and configure an Apache virtual host for port 443 for the local site. 
It will require you to add the SSLEngine, SSLCertificateFile, and SSLCertificateKeyFile 
directives, and point the last two to the certificate and key file you just created.


<VirtualHost *:443>
   ServerName hellfish.test
   DocumentRoot /var/www/hellfish-test

   SSLEngine on
   SSLCertificateFile /path/to/certs/hellfish.test.crt
   SSLCertificateKeyFile /path/to/certs/hellfish.test.key
</VirtualHost>
