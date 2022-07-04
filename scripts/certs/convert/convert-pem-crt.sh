#!/bin/bash
# openssl x509 -outform der -in certificate.pem -out certificate.crt
# openssl x509 -outform der -in certificate.pem -out certificate.crt
 
in="$(realpath "${1}")"
ext=$(filepart $in ext)
outdir=$(filepart $in dir)
outbase=$(filepart $in base)

if [ "$ext" = "pem" ]
then
	openssl x509 -outform der -in "${in}" -out "${outdir}${outbase}.crt"
	echo "Successfully converted ${in} to ${outdir}${outbase}.crt"
else
	echo "Please provide a .pem file as input"
fi

