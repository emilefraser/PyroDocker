#!/bin/bash
# Script Name: AtoMiC Integration Test shellcheck check

SCRIPTPATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
source "$SCRIPTPATH/inc/commons.sh"

shellcheck -V

# Check for Shellcheck errors in the code.
NoShellCheckCodeWarningsFound=$(find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1017 -e SC1090 -e SC2034 -e SC2086 -e SC2215)
if [[ -n $NoShellCheckCodeWarningsFound ]] ; then
    echo -e "${RED}Shellcheck warnings found$ENDCOLOR"
    find . -name '*.sh' -print0 | xargs -0 shellcheck -e SC1017 -e SC1090 -e SC2034 -e SC2086 -e SC2215
    exit 1
fi

# Search for ShellCheck Warnings in all the scripts and fail if it finds any
NoSCDISABLED=$(grep -r '^# shellcheck disable' "$SCRIPTPATH" | grep -c 'shellcheck disable')
if [[ $NoSCDISABLED -gt 0 ]] ; then
    echo -e "${RED}Shellcheck disable warnings found$ENDCOLOR"
    grep -rn "$SCRIPTPATH" -e '^# shellcheck disable'
    exit 1
fi
