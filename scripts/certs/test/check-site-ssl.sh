#!/usr/bin/env bash

get_chain(){
    if [[ "$1" == *":"* ]];then
        port=$(echo $1|cut -d ':' -f2)
        host=$(echo $1|cut -d ':' -f1)
    else
        port=443; host=$1
    fi
    [ ! -z $debug ] && set -x
    res=$(openssl s_client -connect $host:$port -showcerts -servername $host -tls1 -status </dev/null 2>/dev/null)
    set +x
    if [ ! -z "$res" ];then
        if [[ "$res" == *"no peer certificate available"* ]]; then
            chain=2
        else
            chain=$(echo "$res" | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p')
        fi
    else
        chain=1
    fi

    check_stapling "$res"

}

check_stapling(){
    stapling="0"
    echo "$@" | grep "OCSP Response Data:" &>/dev/null && stapling="1"
    if [ "$stapling" -eq "1" ];then
        chain=$(echo "$@" | sed -ne '/===/,/===/!p' | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p')
        staple=$(echo "$@" | sed -ne '/===/,/===/p')
    fi

}

split_chain(){
    echo "$@"  | awk '{print > "__'$host'" (0+n) ".crt"} /-----END CERTIFICATE-----/ {n++}'
}

parse_args(){
    [ -z "$1" ] && usage && exit
    for opt in "$@"; do
        if [ ${opt:0:1} == "-" ];then
            case "$opt" in
                --debug)    debug=1
                        ;;
                --crl)      crlopt=1
                        ;;
                *)      echo -en "Unknown option '$opt'\n\n"
                        usage
            esac
        else
            server="$opt"
        fi
    done
}

usage(){
    echo "Usage:"
    echo "      $0 <remote_server>[:<port>] [--debug] [--crl]"
    echo ""
    echo "Examples:"
    echo "      $0 google.com"
    echo "      $0 google.com:443"
    echo "      $0 google.com --crl"
    echo "      $0 google.com --debug"
    exit
}

dertopem(){
    openssl x509 -in $1 -inform DER -out $1 -outform PEM 2>/dev/null
}

ocsp(){
    echo -en "\nOCSP check:\n"
    [ "$(file -b $1)" == "data" ] && dertopem $1
    ocsphost=$(echo $3 | awk -F'/' {'print $3'})
    [ ! -z $debug ] && set -x
    openssl ocsp -no_cert_verify -issuer $1 -serial 0x$2 -url $3 -header Host $ocsphost
    set +x
}

download(){
    wget --no-check-certificate $1 2>/dev/null
    [ $? != 0 ] && echo 1 || echo ${1##*/} | sed 's/\%20/ /g'
}

checkIssuer(){
    cert_subject="$1"
    cert_issuer="$2"
    sub_issuer=$(openssl x509 -in $cert_subject -noout -issuer | cut -d '=' -f2-)
    iss_subject=$(openssl x509 -in $cert_issuer -noout -subject | cut -d '=' -f2-)
    [ "$sub_issuer" != "$iss_subject" ] && echo -en "\n**************************\nChain's order seems wrong!\n**************************\n\n" && alert=1

}

checkCRL(){
    [ "$(file -b "$2")" == "data" ] && inform="DER" || inform="PEM"
    crl_txt=$(openssl crl -in "$2" -inform $inform -noout -text)
    crl_res=$(echo $crl_txt | grep -c "Serial Number: $1")
    echo "$crl_res$crl_txt"
}

depCheck(){
    for b in wget awk openssl cut sed ;do
        which $b &>/dev/null
        [ $? != 0 ] && echo "Some dependencies are missing ($b)" && exit
    done
}


depCheck
parse_args "$@"


get_chain $server

[ "$chain" == "1" ] && echo Connection to $server failed && exit
[ "$chain" == "2" ] && echo No peer certificate available && exit


host=$(echo $server | cut -d ':' -f1)

split_chain "$chain"

i=1
alert=''

if [ ! -z "$staple" ]; then
    echo -en "+++++++++++++++++++++++++++++++\n"
    echo -en "OCSP Stapling detected\n\n"
    echo "$staple" | grep -A14 "OCSP Response Data"
    echo -en "+++++++++++++++++++++++++++++++\n"
else
    echo -en "+++++++++++++++++++++++++++++++\n"
    echo NO OCSP Stapling detected
    echo -en "+++++++++++++++++++++++++++++++\n"
fi
for c in __$host*.crt;do
    if [ -f __$host$i.crt ];then
        [ -z "$alert" ] && checkIssuer $c __$host$i.crt
    fi
    serial="$(openssl x509 -in $c -noout -serial | sed 's/serial\=//')"
    cert=$(openssl x509 -in $c -noout -text )
    ocsp=$(echo "$cert" | grep "OCSP - URI" | cut -d '-' -f2- | cut -d ':' -f2-)
    notbefore=$(echo "$cert" | grep "Not Before" | cut -d ':' -f2-)
    notafter=$(echo "$cert" | grep "Not After" | cut -d ':' -f2-)
    CN=$(echo "$cert" | grep "Subject:" | cut -d ':' -f2-)
    issuer=$(echo "$cert" | grep "Issuer:" | cut -d ':' -f2-)
    dns=$(echo "$cert" | grep "DNS:" | sed 's/ //g' | sed 's/,/ /g' | sed 's/DNS\://g' )
    crl=$(echo "$cert" | grep -i "\.crl" | sed 's/URI://g' | sed ':a;N;$!ba;s/\n/,/g' | sed 's/ //g' | cut -d ',' -f1)
    alg=$(echo "$cert" | grep -m1 "Signature Algorithm:" | cut -d ':' -f2-)
    echo "[$i]"
    echo "Subject:$CN" 
    echo "Issuer:$issuer"
    echo "Serial: $serial"
    echo "Signature Algorithm: $alg"
    [ -z "$dns" ] || echo "Alternative Names: $dns"
    echo "        Not Before:$notbefore"
    echo "        Not After:$notafter"
    if [ ! -z "$ocsp" ]; then
        if [ -f __$host$i.crt ];then
            ocsp __$host$i.crt $serial $ocsp 
        else
            if [ ! -z "$cacerts" ];then
                echo -en "\nDownloading issuer's certificate for OCSP validation...\n"
                cacert=$(download $(echo $cacerts | cut -d ' ' -f1))
                ocsp $cacert $serial $ocsp
                rm $cacert
            else
                echo -en "\nCertificate has AIA extension but could not find issuer's certificate. Skipping OCSP validation.\n"
            fi
        fi
    else
        echo -en "\nOCSP server not found\n"
    fi

    if [ ! -z "$crlopt" ];then
        if [ ! -z "$crl" ];then
            f_crl=$(download $crl)
            echo -en "\nCRL check\n"
            echo -en "    CDP: $crl\n"
            if [ "${#f_crl}" == 1 ];then
                echo "    Unable to download CRL"
            else
                crl_stat=$(checkCRL $serial "$f_crl")
                lastupdate=$(echo "$crl_stat" | grep "Last Update:" | cut -d ':' -f2-)
                nextupdate=$(echo "$crl_stat" | grep "Next Update:" | cut -d ':' -f2-)
                echo -en "        Last Update:$lastupdate\n"
                echo -en "        Next Update:$nextupdate\n"
                echo -en "        Cert status: "
                [ "${crl_stat:0:1}" == "1" ] && echo -en "REVOKED!\n" || echo -en "OK\n"
            fi
            
        else
            echo -en "\nNo CDP extension found in certificate.\n"
        fi
        rm -f "$f_crl"
    fi
    echo
    echo "#########################"
    i=$((i+1))
done

[ -z $debug ] && rm -f __$host*


