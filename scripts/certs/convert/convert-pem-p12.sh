#!/bin/bash
# penssl pkcs12 -export -out certificate.pfx -inkey privateKey.key -in certificate.crt -certfile CACert.crt

inkey="$(realpath "${1}")"
incert="$(realpath "${2}")"
inca="$(realpath "${3}")"
ext=$(filepart $incert ext)
outdir=$(filepart $incert dir)
outbase=$(filepart $incert base)

openssl pkcs12 -export -out "${outdir}${outbase}.p12" -inkey "${inkey}" -in "${incert}" -certfile "${inca}"
echo "Successfully exported ${outdir}${outbase}.p12"

