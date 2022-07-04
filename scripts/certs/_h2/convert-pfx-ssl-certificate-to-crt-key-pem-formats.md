source: http://www.markbrilman.nl/2011/08/howto-convert-a-pfx-to-a-seperate-key-crt-file/

`openssl pkcs12 -in [yourfile.pfx] -nocerts -out [keyfile-encrypted.key]`

What this command does is extract the private key from the .pfx file. Once entered you need to type in the importpassword of the .pfx file.  This is the password that you used to protect your keypair when you created your .pfx file.  If you cannot remember it anymore you can just throw your .pfx file away, cause you won’t be able to import it again, anywhere!.  Once you entered the import password OpenSSL requests you to type in another password, twice!. This new password will protect your .key file.

Now let’s extract the certificate:

`openssl pkcs12 -in [yourfile.pfx] -clcerts -nokeys -out [certificate.crt]`

Just press enter and your certificate appears.

Now as I mentioned in the intro of this article you sometimes need to have an unencrypted .key file to import on some devices.  I probably don’t need to mention that you should be carefully. If you store your unencrypted keypair somewhere on an unsafe location anyone can have a go with it and impersonate for instance a website or a person of your company.  So always be extra careful when it comes to private keys! Just throw the unencrypted keyfile away when you’re done with it, saving just the encrypted one.

The command:

`openssl rsa -in [keyfile-encrypted.key] -out [keyfile-decrypted.key]`

Notes:
- When you first extract the key, apply a new password (probably the same as you used to extract it) and then create an unencrypted key with the rsa command above
- Use an encrypted key file for NGINX otherwise it'll ask for the password every time it is restarted.
- Check the top of the extract .crt file for extra bits above the ----BEING... line and remove if necessary
- This certificated needs to be concatenated with the full chain of certificate authorities `cat domain.crt CA_bundle.crt > final.crt`
- test the cert with `openssl s_client -showcerts -connect www.domain.com:443`