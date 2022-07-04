#!/bin/bash

fn=""
inform="${1}"
ext=""
outfile=basename ${1}

openssl "${fn}" -nokeys -in "${inform}" -out "${outfile}.${ext}"

