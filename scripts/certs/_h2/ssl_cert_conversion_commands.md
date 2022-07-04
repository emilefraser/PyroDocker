Use below command to convert certificate format

1.	Convert .CRT to .PEM format
- openssl x509 -inform der -in c:\Certificate\user2.crt (Your directory path) -out c:\Certificate\certificate_1.pem (Your directory path)

2.	Convert .CRT to .PFX format
- openssl pkcs12 -export -out c:\Certificate\certificate.pfx -inkey c:\Certificate\certificate_1.pem -in c:\Certificate\user2.crt

3.	Convert .PEM to .DER format
- openssl x509 -outform der -in c:\Certificate\certificatename.pem -out c:\Certificate\certificatename.der

4.	Convert .DER to .PEM format
- openssl x509 -inform der -in c:\Certificate\certificatename.der -out c:\Certificate\certificatename.pem

5.	Convert .PFX to .PEM format
- The PKCS#12 or PFX format is a binary format for storing the server certificate, intermediate certificates, and the private key in one encryptable file. PFX files usually have extensions such as .pfx and .p12. PFX files are typically used on Windows machines to import and export certificates and private keys.

6.	Generate private key from .CRT file
- install the crt file /pem file certificate
- openssl genrsa -out (certificate path+certficiate name)  2048 ( example - openssl genrsa -out user.crt  2048). 
- make sure you are on the same directory where the certificate is saved
- go to keychain access ( on mac) , open the certficate key ( right click and export as p.12)
- open the p.12 file in a code editor to find your private key 

