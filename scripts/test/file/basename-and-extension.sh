#!/bin/bash
for fullpath in "$@"
do
    # test whether dir or file
    if [ -d "$fullpath" ]
    then
        abspath="$(realpath "$fullpath")/"
    else
        abspath="$(realpath "$fullpath")"
    fi

    filename="${abspath##*/}"                      # Strip longest match of */ from start
    dir="${abspath:0:${#abspath} - ${#filename}}" # Substring from 0 thru pos of filename
    folder="$(basename $(dirname "$abspath"))"
    base="${filename%.[^.]*}"                       # Strip shortest match of . plus at least one non-dot char from end
    ext="${filename:${#base} + 1}"                  # Substring from len of base thru end
    if [[ -z "$base" && -n "$ext" ]]; then          # If we have an extension and no base, it's really the base
        base=".$ext"
        ext=""
    fi

    echo -e "*** $fullpath ***\n\tpath   = \"$abspath\"\n\tdir    = \"$dir\"\n\tfolder = \"$folder\"\n\tfile   = \"$filename\"\n\tbase   = \"$base\"\n\text    = \"$ext\"\n"
done
