#!/bin/bash
# openssl crl2pkcs7 -nocrl -certfile certificate.cer -out certificate.p7b -certfile CACert.cer

incert="$(realpath "${1}")"
inca="${realpath "${2}")"
ext=$(filepart $incert ext)
outdir=$(filepart $incert dir)
outbase=$(filepart $incert base)

if [ "$ext" = "pem" ]
then
	openssl crl2pkcs7 -nocrl -certfile "${incert}" -certfile "${inca}" -out "${outdir}${outbase}.p7b"
	echo "Successfully converted ${in} to ${outdir}${outbase}.p7b"
else
	echo "Please provide a .pem file as input"
fi
