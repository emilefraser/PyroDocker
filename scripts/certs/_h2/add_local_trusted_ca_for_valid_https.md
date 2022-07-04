# Generating SSL keys for development

## Installation

Thanks to [minica](https://github.com/jsha/minica) it is very easy to create trusted SSL certificates that have a very long expiration date.

In order to get started you have to have the [go tools](https://golang.org/dl/) installed and set up correctly in your environment.

## Setup

Once that is done you should adapt `gen_certs.sh` to fit your needs. There should be an entry for each domain you want to create a certificate for and the subdomains must be specified as the certificate is not a wildcard one.

The `rm -rf domain.com` line is here, because `minica` doesn't overwrite existing certificates.

For example, if your development server needs to listen to https://some.domain.cool the entry for it should be

```

rm -rf domain.cool
minica --domains domain.cool,some.domain.cool
```
After that you can simply run `gen_certs.sh` and the certificates will be generated.

Upon run there will be a new folder containing a `cert.pem` and a `key.pem` file. Those can be added in the configuration of the webserver.

```
# the cert files and key location
SSLCertificateFile /etc/apache2/certs/domain.cool/cert.pem
SSLCertificateKeyFile /etc/apache2/certs/domain.cool/key.pem
```

Change the paths to match the ones specified.

Restaring the webeserver will still show you that the certificates are invalid. That's because the root authority has not yet been trusted.

## Trusting minica

In the root folder, right next to `gen_certs.sh` file you will find two new files: `minica.pem` (the certificate) and `minica-key.pem` (the key). These files contain the Certificate and key to add minica as a Trusted Root Certification Authority on your local machine. Those will need to be added to your local keystore.

### Windows

The steps on Windows are pretty easily achieved (props to [childno.de](https://superuser.com/a/830520/115234)):

1. start `mmc.exe` as Admin
1. `File` > `Add/Remove Snap-in...`
1. Look for the `Certifactes` Snap-in and `Add >` it
1. Choose `Computer Account` when prompted and hit finish
1. Mark the `Trusted Root Certification Authoritiy` entry in the tree and right click it. In the context menu choose `All Tasks` > `Import...`
1. Navigate to the folder where `minica.pem` is located. Don't worry about the file extension, just choose to display all files.
1. Select `minica.pem`, choose `Open` and leave the following options as is.
1. Look for an entry starting `minica root ca` in the list.
1. Restart your browsers.

Your certificates are now trusted.

### Mac

On Mac it is not much work [see here](https://support.untangle.com/hc/en-us/articles/212220648-Manually-installing-root-certificate-on-Mac-OSX)

1. open `Keychain Access`
1. `File`> `import items...`
1. Select minica.pem
1. Right click on `minica root ca` choose `get info`
1. Open `Trust` and select `Always Trust` on `When using this certificate`
1. Restart your browsers.

Your certificates are now trusted.

### Linux (Debian/Ubuntu)
Also have a look [here](https://thomas-leister.de/en/how-to-import-ca-root-certificate/):

**System**

Install the root certifcate on your system
```
sudo cp minica.pem /usr/local/share/ca-certificates/minica.crt
sudo chmod 644 /usr/local/share/ca-certificates/minica.crt
sudo update-ca-certificates
```

Verify your system utilities like `curl` or `wget` recognize the certificate:
```
curl https://local.vn.at -v 2>&1 | grep -i 'minica root'
```

**Browser (Firefox, Chromium,...)**

Linux doesn't have a Trustore unlike Mac.

Instead of adding the certificate manually for each application lazy developers use a script.

First install the `certutil` tool.

```
sudo apt install libnss3-tools
```

This scripts finds trust store databases and imports the new root certificate into them.
```
#!/bin/sh

### Script installs minica.pem to certificate trust store of applications using NSS
### (e.g. Firefox, Thunderbird, Chromium)
### Mozilla uses cert8, Chromium and Chrome use cert9

###
### Requirement: apt install libnss3-tools
###


###
### CA file to install (customize!)
### Retrieve Certname: openssl x509 -noout -subject -in minica.pem
###

certfile="minica.pem"
certname="minica root ca"



###
### For cert8 (legacy - DBM)
###

for certDB in $(find ~/ -name "cert8.db")
do
    certdir=$(dirname ${certDB});
    certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d dbm:${certdir}
done


###
### For cert9 (SQL)
###

for certDB in $(find ~/ -name "cert9.db")
do
    certdir=$(dirname ${certDB});
    certutil -A -n "${certname}" -t "TCu,Cu,Tu" -i ${certfile} -d sql:${certdir}
done

```

Restart your browsers.

Your certificates are now trusted.
