#!/bin/bash
# openssl pkcs7 -print_certs -in certificate.p7b -out certificate.cer

in="$(realpath "${1}")"
ext=$(filepart $in ext)
outdir=$(filepart $in dir)
outbase=$(filepart $in base)

if [ "$ext" = "p7b" ]
then
	openssl pkcs7 -print_certs -in "${incert}" -out "${outdir}${outbase}.cer"
	echo "Successfully converted ${in} to ${outdir}${outbase}.cer"
else
	echo "Please provide a .p7b file as input"
fi
