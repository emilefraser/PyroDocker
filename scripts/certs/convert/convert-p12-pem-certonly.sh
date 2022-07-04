#!/bin/bash
# openssl pkcs12 -in keyStore.p12 -out keyStore.pem -nodes

in="$(realpath "${1}")"
ext=$(filepart $in ext)
outdir=$(filepart $in dir)
outbase=$(filepart $in base)

if [ "$ext" = "p12" ]
then
	openssl pkcs12 -in "${in}" -out "${outdir}${outbase}.pem -nodes -nokeys"
	echo "Successfully converted ${in} to ${outdir}${outbase}.pem"
else
	echo "Please provide a .p12 file as input"
fi
