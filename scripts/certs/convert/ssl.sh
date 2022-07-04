

Converting Using OpenSSL

These commands allow you to convert certificates and keys to different formats to make them compatible with specific types of servers or software.

    Convert a DER file (.crt .cer .der) to PEM

    openssl x509 -inform der -in certificate.cer -out certificate.pem

    Convert a PEM file to DER

    openssl x509 -outform der -in certificate.pem -out certificate.der

    Convert a PKCS#12 file (.pfx .p12) containing a private key and certificates to PEM

    openssl pkcs12 -in keyStore.pfx -out keyStore.pem -nodes

    You can add -nocerts to only output the private key or add -nokeys to only output the certificates.

    Convert a PEM certificate file and a private key to PKCS#12 (.pfx .p12)

    openssl pkcs12 -export -out certificate.pfx -inkey privateKey.key -in certificate.crt -certfile CACert.crt

    Convert PEM to CRT (.CRT file)

    openssl x509 -outform der -in certificate.pem -out certificate.crt

OpenSSL Convert PEM

    Convert PEM to DER

    openssl x509 -outform der -in certificate.pem -out certificate.der

    Convert PEM to P7B

    openssl crl2pkcs7 -nocrl -certfile certificate.cer -out certificate.p7b -certfile CACert.cer

    Convert PEM to PFX

    openssl pkcs12 -export -out certificate.pfx -inkey privateKey.key -in certificate.crt -certfile CACert.crt

OpenSSL Convert DER

    Convert DER to PEM

    openssl x509 -inform der -in certificate.cer -out certificate.pem

OpenSSL Convert P7B

    Convert P7B to PEM

    openssl pkcs7 -print_certs -in certificate.p7b -out certificate.cer

    Convert P7B to PFX

    openssl pkcs7 -print_certs -in certificate.p7b -out certificate.cer

    openssl pkcs12 -export -in certificate.cer -inkey privateKey.key -out certificate.pfx -certfile CACert.cer

OpenSSL Convert PFX

    Convert PFX to PEM

    openssl pkcs12 -in certificate.pfx -out certificate.cer -nodes

Generate rsa keys by OpenSSL

    Using OpenSSL on the command line you’d first need to generate a public and private key, you should password protect this file using the -passout argument, there are many different forms that this argument can take so consult the OpenSSL documentation about that.

    openssl genrsa -out private.pem 1024

    This creates a key file called private.pem that uses 1024 bits. This file actually have both the private and public keys, so you should extract the public one from this file:

    openssl rsa -in private.pem -out public.pem -outform PEM -pubout

    or

    openssl rsa -in private.pem -pubout > public.pem

    or

    openssl rsa -in private.pem -pubout -out public.pem

        You’ll now have public.pem containing just your public key, you can freely share this with 3rd parties. You can test it all by just encrypting something yourself using your public key and then decrypting using your private key, first we need a bit of data to encrypt:

    Example file :

    echo 'too many secrets' > file.txt

    You now have some data in file.txt, lets encrypt it using OpenSSL and the public key:

    openssl rsautl -encrypt -inkey public.pem -pubin -in file.txt -out file.ssl

    This creates an encrypted version of file.txt calling it file.ssl, if you look at this file it’s just binary junk, nothing very useful to anyone. Now you can unencrypt it using the private key:

    openssl rsautl -decrypt -inkey private.pem -in file.ssl -out decrypted.txt

    You will now have an unencrypted file in decrypted.txt:

    cat decrypted.txt
    |output -> too many secrets

RSA TOOLS Options in OpenSSL

    NAME

        rsa - RSA key processing tool

    SYNOPSIS

        openssl rsa [-help] [-inform PEM|NET|DER] [-outform PEM|NET|DER] [-in filename] [-passin arg] [-out filename] [-passout arg] [-aes128] [-aes192] [-aes256] [-camellia128] [-camellia192] [-camellia256] [-des] [-des3] [-idea] [-text] [-noout] [-modulus] [-check] [-pubin] [-pubout] [-RSAPublicKey_in] [-RSAPublicKey_out] [-engine id]

    DESCRIPTION

        The rsa command processes RSA keys. They can be converted between various forms and their components printed out. Note this command uses the traditional SSLeay compatible format for private key encryption: newer applications should use the more secure PKCS#8 format using the pkcs8 utility.

    COMMAND OPTIONS

    -help

        Print out a usage message.

    -inform DER|NET|PEM

        This specifies the input format. The DER option uses an ASN1 DER encoded form compatible with the PKCS#1 RSAPrivateKey or SubjectPublicKeyInfo format. The PEM form is the default format: it consists of the DER format base64 encoded with additional header and footer lines. On input PKCS#8 format private keys are also accepted. The NET form is a format is described in the NOTES section.

    -outform DER|NET|PEM

        This specifies the output format, the options have the same meaning as the -inform option.

    -in filename

        This specifies the input filename to read a key from or standard input if this option is not specified. If the key is encrypted a pass phrase will be prompted for.

    -passin arg

        the input file password source. For more information about the format of arg see the PASS PHRASE ARGUMENTS section in openssl.

    -out filename

        This specifies the output filename to write a key to or standard output if this option is not specified. If any encryption options are set then a pass phrase will be prompted for. The output filename should not be the same as the input filename.

    -passout password

        the output file password source. For more information about the format of arg see the PASS PHRASE ARGUMENTS section in openssl.

    -aes128|-aes192|-aes256|-camellia128|-camellia192|-camellia256|-des|-des3|-idea

        These options encrypt the private key with the specified cipher before outputting it. A pass phrase is prompted for. If none of these options is specified the key is written in plain text. This means that using the rsa utility to read in an encrypted key with no encryption option can be used to remove the pass phrase from a key, or by setting the encryption options it can be use to add or change the pass phrase. These options can only be used with PEM format output files.

    -text

        prints out the various public or private key components in plain text in addition to the encoded version.

    -noout

        this option prevents output of the encoded version of the key.

    -modulus

        this option prints out the value of the modulus of the key.

    -check

        this option checks the consistency of an RSA private key.

    -pubin

        by default a private key is read from the input file: with this option a public key is read instead.

    -pubout

        by default a private key is output: with this option a public key will be output instead. This option is automatically set if the input is a public key.

    -RSAPublicKey_in, -RSAPublicKey_out

        like -pubin and -pubout except RSAPublicKey format is used instead.

    -engine id

        specifying an engine (by its unique id string) will cause rsa to attempt to obtain a functional reference to the specified engine, thus initialising it if needed. The engine will then be set as the default for all available algorithms.

    NOTES

    The PEM private key format uses the header and footer lines:

    -----BEGIN RSA PRIVATE KEY-----

    -----END RSA PRIVATE KEY-----

    The PEM public key format uses the header and footer lines:

    -----BEGIN PUBLIC KEY-----

    -----END PUBLIC KEY-----

    The PEM RSAPublicKey format uses the header and footer lines:

    -----BEGIN RSA PUBLIC KEY-----

    -----END RSA PUBLIC KEY-----

        The NET form is a format compatible with older Netscape servers and Microsoft IIS .key files, this uses unsalted RC4 for its encryption. It is not very secure and so should only be used when necessary.

        Some newer version of IIS have additional data in the exported .key files. To use these with the utility, view the file with a binary editor and look for the string "private-key", then trace back to the byte sequence 0x30, 0x82 (this is an ASN1 SEQUENCE). Copy all the data from this point onwards to another file and use that as the input to the rsa utility with the -inform NET option.

    EXAMPLES

    To remove the pass phrase on an RSA private key:

     openssl rsa -in key.pem -out keyout.pem

    To encrypt a private key using triple DES:

     openssl rsa -in key.pem -des3 -out keyout.pem

    To convert a private key from PEM to DER format:

      openssl rsa -in key.pem -outform DER -out keyout.der

    To print out the components of a private key to standard output:

      openssl rsa -in key.pem -text -noout

    To just output the public part of a private key:

      openssl rsa -in key.pem -pubout -out pubkey.pem

    Output the public part of a private key in RSAPublicKey format:

      openssl rsa -in key.pem -RSAPublicKey_out -out pubkey.pem

