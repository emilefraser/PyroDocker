#!/bin/bash


openssl req -new -key hellfish.test.key -out hellfish.test.csr


You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:Springfield State
Locality Name (eg, city) []:Springfield
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Hellfish Media
Organizational Unit Name (eg, section) []:7G
Common Name (e.g. server FQDN or YOUR name) []:Hellfish Media
Email Address []:asimpson@hellfish.media

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
#wAn optional company name []:
