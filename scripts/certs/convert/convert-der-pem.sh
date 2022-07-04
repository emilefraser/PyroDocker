#!/bin/bash
# openssl x509 -inform der -in certificate.cer -out certificate.pem

in="$(realpath "${1}")"
ext=$(filepart $in ext)
outdir=$(filepart $in dir)
outbase=$(filepart $in base)

if [ "$ext" = "der"
then
	openssl x509 -inform der -in "${in}" -out "${outdir}${outbase}.pem"
	echo "Successfully converted ${in} to ${outdir}${outbase}.pem"
else
	echo "Please provide a .der file as input"
fi
