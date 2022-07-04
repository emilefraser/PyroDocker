#!/bin/bash
# openssl x509 -outform der -in certificate.pem -out certificate.cer

in="$(realpath "${1}")"
ext=$(filepart $in ext)
outdir=$(filepart $in dir)
outbase=$(filepart $in base)

if [ "$ext" = "pem" ]
then
	openssl x509 -outform der -in "${in}" -out "${outdir}${outbase}.cer"
	echo "Successfully converted ${in} to ${outdir}${outbase}.cer"
else
	echo "Please provide a .pem file as input"
fi
