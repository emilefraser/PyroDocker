#!/bin/bash
# openssl pkcs12 -export -in certificate.cer -inkey privateKey.key -out certificate.pfx -certfile CACert.cer

inkey="${realpath "${1}"}"
incert="$(realpath "${2}")"
inca="${realpath "${3}")"
ext=$(filepart $incert ext)
outdir=$(filepart $incert dir)
outbase=$(filepart $incert base)

if [ "$ext" = "cer" ]
then
	openssl pkcs12 -export -in "${incert}" -inkey "${inkey}" -certfile "${inca}" -out "${outdir}${outbase}.pfx"
	echo "Successfully converted ${in} to ${outdir}${outbase}.pfx"
else
	echo "Please provide a .cer file as input"
fi
