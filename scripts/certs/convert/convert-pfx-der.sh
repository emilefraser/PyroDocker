#!/bin/bash
# openssl pkcs12 -in keyStore.pfx -out keyStore.pem -nodes

in="$(realpath "${1}")"
ext=$(filepart $in ext)
outdir=$(filepart $in dir)
outbase=$(filepart $in base)

if [ "$ext" = "pfx" ]
then
	openssl pkcs12 -in "${in}" -out "${outdir}${outbase}.der -nodes"
	echo "Successfully converted ${in} to ${outdir}${outbase}.der"
else
	echo "Please provide a .pfx file as input"
fi
