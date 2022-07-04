#!/bin/sh

#   ____ _____ ____ _____ ___ _____ ___ ____    _  _____ _____ ____
#  / ___| ____|  _ \_   _|_ _|  ___|_ _/ ___|  / \|_   _| ____/ ___|
# | |   |  _| | |_) || |  | || |_   | | |     / _ \ | | |  _| \___ \
# | |___| |___|  _ < | |  | ||  _|  | | |___ / ___ \| | | |___ ___) |
#  \____|_____|_| \_\|_| |___|_|   |___\____/_/   \_\_| |_____|____/

#  ____  _______  __
# |  _ \|  ___\ \/ /
# | |_) | |_   \  /
# |  __/|  _|  /  \
# |_|   |_|   /_/\_\

# BACKGROUND INFO
#   A private standard that provides enhanced security versus the plain-text PEM format. 
#   It's used preferentially by Windows systems, and can be freely converted to PEM format through use of openssl.
#   http://serverfault.com/questions/9708/what-is-a-pem-file-and-how-does-it-differ-from-other-openssl-generated-key-file
# 
#   PKCS #12 is the successor to Microsoft's "PFX"
#   The terms "PKCS #12 file" and "PFX file" are sometimes used interchangeably.
#   PKCS #12 defines an archive file format for storing many cryptography objects as a single file. 
#   It is commonly used to bundle a private key with its X.509 certificate
#   

# CONVERSION EXAMPLES

# PFX to PEM: Extract X.509 certificate
openssl pkcs12 -in cert-with-public-and-private-keys.pfx -clcerts -nokeys -out cert.pem

# PFX to PEM: Extract private key
openssl pkcs12 -in cert-with-public-and-private-keys.pfx -nocerts -out private-key.pem

# Remove password from private key just exported
openssl rsa -in private-key.pem -out private.pem


#  ____  _____ __  __
# |  _ \| ____|  \/  |
# | |_) |  _| | |\/| |
# |  __/| |___| |  | |
# |_|   |_____|_|  |_|

# BACKGROUND INFO
#   Governed by RFCs, it's used preferentially by open-source software. 
#   It can have a variety of extensions (.pem, .key, .cer, .cert, more)
#   It's a base64 representation of DER with header and footer information 

# CONVERSION EXAMPLES

# PEM to DER
openssl x509 -outform der -in certificate.pem -out certificate.der

# PEM to PFX 
openssl pkcs12 -export -out certificate.pfx -inkey privateKey.key -in certificate.crt -certfile CAcert.crt

#  ____  _____ ____
# |  _ \| ____|  _ \
# | | | |  _| | |_) |
# | |_| | |___|  _ <
# |____/|_____|_| \_\

# BACKGROUND INFO
#   The parent format of PEM. It's useful to think of it as a binary version of the base64-encoded PEM file. 
#   Not routinely used by anything in common usage. 
#   Was used primarily by Java and Macintosh platforms

# CONVERSION EXAMPLES

# DER to PEM
openssl x509 -inform der -in certificate.cer -out certificate.pem

# PEM to DER
openssl x509 -in cert.pem -out cert.der -outform DER 

# ---------------------------------------------------------
# References
# http://serverfault.com/questions/9708/what-is-a-pem-file-and-how-does-it-differ-from-other-openssl-generated-key-file
# http://www.gtopia.org/blog/2010/02/der-vs-crt-vs-cer-vs-pem-certificates/
# http://en.wikipedia.org/wiki/PKCS_12
# http://support.citrix.com/article/CTX106631
