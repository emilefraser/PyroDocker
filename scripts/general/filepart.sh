#!/bin/bash
fullpath="${1}"
filepart="${2}"

# test whether dir or file
if [ -d "$fullpath" ]
then
    abspath="$(realpath "$fullpath")/"
else
    abspath="$(realpath "$fullpath")"
fi

file="${abspath##*/}"
dir="${abspath:0:${#abspath} - ${#file}}"
folder="$(basename $(dirname "$abspath"))"
base="${file%.[^.]*}"
ext="${file:${#base} + 1}"

if [[ -z "$base" && -n "$ext" ]]
then
    base=".$ext"
    ext=""
fi

echo ${!filepart}
