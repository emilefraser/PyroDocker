#!/usr/bin/env bash

# LabCA: a private Certificate Authority for internal lab usage
# (c) 2018-2022 Arjan Hakkesteegt
#
# Install with this command from a Linux machine (only tested with Debian and Ubuntu):
# curl -sSL https://raw.githubusercontent.com/hakwerk/labca/master/install | bash

set -e

#
# Variables / Constants
#
baseDir=/home/labca
logDir="$baseDir/logs"
runId="`date +%y%m%d-%H%M%S`"
installLog="$logDir/install-${runId}.log"
logTimeFormat="+%Y-%m-%d %T.%3N"
cloneDir="$baseDir/labca"
adminDir="$baseDir/admin"
boulderDir="$baseDir/boulder"
boulderLabCADir="${boulderDir}_labca"
dockerComposeVersion="v2.5.0"

labcaUrl="https://github.com/hakwerk/labca/"
boulderUrl="https://github.com/letsencrypt/boulder/"
boulderTag="release-2022-05-09"

# Feature flags
flag_skip_redis=true

#
# Color configuration
#
COL_NC='\e[0m' # No Color
COL_LIGHT_GREEN='\e[1;32m'
COL_LIGHT_RED='\e[1;31m'
TICK="[${COL_LIGHT_GREEN}✓${COL_NC}]"
CROSS="[${COL_LIGHT_RED}✗${COL_NC}]"
INFO="[.]"
DONE="${COL_LIGHT_GREEN} done!${COL_NC}"
OVER="\\r\\033[K"

# Dummy implementation in case utils.sh is not available (install via curl method)
wait_down() {
    sleep 1
}
wait_up() {
    sleep 5
}

dn=$(dirname $0)
source "$dn/utils.sh" &>/dev/null || true

cmdlineFqdn=""
cmdlineBranch=""
fullCmdline=""
keepLocal=0

#
# Helper functions for informing the user and logging to file
#
msg_info() {
    local msg="$1"
    echo -ne "  ${INFO} ${msg}..."
    echo "[`date "${logTimeFormat}"`] [INFO ] ${msg}..." >> $installLog
}

msg_ok() {
    local msg="$1"
    echo -e "${OVER}  ${TICK} ${msg}"
    echo "[`date "${logTimeFormat}"`] [OK   ] ${msg}" >> $installLog
}

msg_err() {
    local msg="$1"
    echo -e "${OVER}  ${CROSS} ${msg}"
    echo "[`date "${logTimeFormat}"`] [ERROR] ${msg}" >> $installLog
}

msg_fatal() {
    local msg="$1"
    echo -e "\\n  ${COL_LIGHT_RED}Error: ${msg}${COL_NC}\\n"
    echo "[`date "${logTimeFormat}"`] [FATAL] ${msg}" >> $installLog
    exit 1
}

#
# Log to /tmp first in case the labca user doesn't exist yet
#
start_temporary_log() {
    backupLog=$installLog
    installLog="/tmp/labca-install.log"
    touch "$installLog"
}

end_temporary_log() {
    mv "$installLog" "$backupLog"
    installLog=$backupLog
    chown labca:labca "$installLog"
}

# Must run as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        msg_ok "Running as root"
    else
        msg_err "Not running as root"

        local msg="Run using sudo"
        if command -v sudo &> /dev/null; then
            msg_ok "$msg"
            exec curl -sSL https://raw.githubusercontent.com/hakwerk/labca/master/install | sudo bash "$@"
            exit $?
        else
            msg_err "$msg"
            echo -e "  ${COL_LIGHT_RED}Script should be run as the root user${COL_NC}"
        fi
    fi
}

# Create dedicated user
labca_user() {
    adduser --gecos "LabCA,,," --disabled-login labca &>>$installLog && msg_ok "Created user 'labca'" || msg_ok "User 'labca' already exists"
    [ -d "$logDir" ] || mkdir "$logDir"
    chown -R labca:labca "$logDir"

    cd ~labca
    local gig=$(sudo -u labca -H git config --global core.excludesfile 2>/dev/null)
    if [ -z "$gig" ]; then
        sudo -u labca -H git config --global core.excludesfile /home/labca/.gitignore_global >/dev/null 2>&1 || msg_info "WARNING: could not set core.excludesfile"
        gig=$(sudo -u labca -H git config --global core.excludesfile 2>/dev/null)
    fi
    gig=${gig/\~/\/home\/labca}
    gig=${gig:-/home/labca/.gitignore_global}

    [ -e "$gig" ] || sudo -u labca -H touch $gig
    sudo -u labca -H grep config_labca "$gig" >/dev/null 2>&1 || sudo -u labca -H echo "config_labca/" >> "$gig"
}

#
# Get the latest code from the git repository
#
clone_repo() {
    local dir="$1"
    local url="$2"
    local branch="$3"

    local msg="Clone $url to $dir"
    msg_info "$msg"
    sudo -u labca -H git clone -q "$url" "$dir" &>>$installLog && msg_ok "$msg" || msg_fatal "Could not clone git repository"

    if [ "$branch" != "" ]; then
        cd "$dir"
        sudo -u labca -H git checkout $branch &>>$installLog
        cd - >/dev/null
    fi
}

pull_repo() {
    local dir="$1"
    local branch="$2"

    cd "$dir" &>>$installLog || msg_fatal "Could not switch to directory '$dir'"

    local msg="Update git repository in $dir"
    msg_info "$msg"
    sudo -u labca -H git stash --all --quiet &>>$installLog || true
    sudo -u labca -H git clean --quiet --force -d &>>$installLog || true
    sudo -u labca -H git pull --quiet &>>$installLog && msg_ok "$msg" || msg_fatal "Could not update local repository"

    if [ "$branch" != "" ]; then
        cd "$dir"
        sudo -u labca -H git checkout $branch &>>$installLog
        cd - >/dev/null
    fi
}

clone_or_pull() {
    local dir="$1"
    local url="$2"
    local branch="$3"

    local parentdir=$(dirname "$dir")
    local dirbase=$(basename "$dir")

    if [ -d "$dir" ]; then
        local rc=0
        cd "$dir"
        git status --short &> /dev/null || rc=$?
        if [ $rc -gt 0 ]; then
            cd "$parentdir"
            mv "$dirbase" "${dirbase}_${runId}" && msg_ok "Backup existing non-git directory '$dir'"
            clone_repo "$dir" "$url" "$branch"
        else
            pull_repo "$dir" "$branch"
        fi
    else
        clone_repo "$dir" "$url" "$branch"
    fi
}

# Checkout the latest release tag
checkout_release() {
    local branch="$1"
    if [ "$branch" == "" ] || [ "$branch" == "master" ] || [ "$branch" == "main" ]; then
        cd "$cloneDir"
        if [ "$curChecksum" == "" ]; then
            curChecksum=$(md5sum $cloneDir/install 2>/dev/null | cut -d' ' -f1)
        fi
        TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
        sudo -u labca -H git reset --hard $TAG &>>$installLog
    fi
}

# Restart the script if it was updated itself
restart_if_updated() {
    local gitRev=$(cd $cloneDir && git describe --always --tags)
    echo "=== version $gitRev ($curChecksum) ===" >>$installLog

    if [ "$curChecksum" != "" ]; then
        local newChecksum=$(md5sum $cloneDir/install 2>/dev/null | cut -d' ' -f1)
        if [ "$curChecksum" != "$newChecksum" ]; then
            msg_info "Restarting updated version of install script"
            echo
            exec $cloneDir/install $fullCmdline
            exit $?
        fi
    fi
}

# Utility method to prompt the user for a config variable and export it
prompt_and_export() {
    local varName="$1"
    local varDefault="$2"
    local promptMsg="$3"
    local answer

    read -p "$promptMsg [$varDefault] " answer </dev/tty
    if [ "$answer" ]; then
        export $varName="$answer"
    else
        export $varName="$varDefault"
    fi
}

# Parse the command line options, if any
parse_cmdline() {
    fullCmdline="$@"
    local parsed=$(getopt --options=n:,b:,k --longoptions=name:,fqdn:,branch:,keep --name "$0" -- "$@" 2>>$installLog) || msg_fatal "Could not process commandline parameters"
    eval set -- "$parsed"
    while true; do
        case "$1" in
            -n|--name|--fqdn)
                cmdlineFqdn="$2"
                shift 2
                msg_ok "option: using FQDN name '$cmdlineFqdn'"
                ;;
            -b|--branch)
                cmdlineBranch="$2"
                shift 2
                msg_ok "option: using branch '$cmdlineBranch'"
                ;;
            -k|--keep)
                keepLocal=1
                shift 1
                msg_ok "option: keeping local version as is"
                ;;
            --)
                shift
                break
                ;;
            *)
                msg_fatal "Should not have reached this"
                ;;
        esac
    done
}

# Utility method to check if value looks like a host + domain
has_domain() {
    local dom="$1"

    if [[ "$dom" =~ ^\..*$ ]]; then
        false
    elif [[ "$dom" =~ ^.*\.$ ]]; then
        false
    elif [[ "$dom" =~ ^.*\..*$ ]]; then
        true
    else
        false
    fi
}

# Determine the remote address of this machine from (in order): commandline parameter,
# existing configuration or full hostname.
get_fqdn() {
    local cfgFile="$adminDir/data/config.json"
    local cfgFqdn=$(grep fqdn $cfgFile 2>/dev/null | grep -v LABCA_FQDN | cut -d ":" -f 2- | tr -d " \",")
    LABCA_FQDN=${cfgFqdn:-$(hostname -f)}

    while [ "$cfgFqdn" == "" ]; do
        if [ "$cmdlineFqdn" != "" ]; then
            export LABCA_FQDN="$cmdlineFqdn"
        else
            prompt_and_export LABCA_FQDN "$LABCA_FQDN" "FQDN (Fully Qualified Domain Name) for this PKI host (users will use this in their browsers and clients)?"
        fi

        if has_domain $LABCA_FQDN; then
            cfgFqdn="ok"
        else
            msg_err "FQDN must include a hostname AND a domain!"
            cmdlineFqdn=""
        fi
    done

    if ! has_domain $LABCA_FQDN; then
        msg_fatal "FQDN must include a hostname AND a domain!"
    fi

    msg_ok "Determine web address"
}

# Utility method to replace all instances of given variables in a file
replace_all() {
    local filename="$1"
    local var

    for var in ${@:2}; do
        sed -i -e "s|$var|${!var}|g" $filename
    done
}

# Copy and configure the admin tree from the local repository
copy_admin() {
    local rc=0

    local msg="Setup admin application"
    msg_info "$msg"

    [ -d "$adminDir" ] || mkdir "$adminDir"
    cd "$adminDir"
    git status --short &> /dev/null || rc=$?
    if [ $rc -gt 0 ]; then
        git init &>>$installLog
    fi
    git add --all &>/dev/null || true
    git commit --all --quiet -m "LabCA before update $runId" &>>$installLog && { msg_ok "Commit existing modifications of $adminDir"; msg_info "$msg"; } || true

    cp -rp $cloneDir/gui/* "./" &>>$installLog || msg_fatal "Cannot copy the admin files to $adminDir"
    cp -p  "$cloneDir/acme_tiny.py" "/home/labca/" &>>$installLog

    msg_ok "$msg"
    msg="Configure the admin application"
    msg_info "$msg"

    [ -e "$adminDir/data/config.json" ] || echo -e "{\n  \"config\": {\n    \"complete\": false\n  },\n  \"labca\": {\n    \"fqdn\": \"$LABCA_FQDN\"\n  },\n  \"version\": \"\"\n}" > "$adminDir/data/config.json"
    replace_all $adminDir/data/openssl.cnf LABCA_FQDN
    replace_all $adminDir/data/issuer/openssl.cnf LABCA_FQDN
    replace_all /home/labca/acme_tiny.py LABCA_FQDN

    cd "$cloneDir"
    version=$(git describe --always --tags HEAD 2>/dev/null)
    cd "$adminDir"
    grep \"version\" data/config.json &>/dev/null || sed -i -e 's/^}$/,\n  "version": ""\n}/' data/config.json
    sed -i -e "s/\"version\": \".*\"/\"version\": \"$version\"/" data/config.json
    [ ! -e bin/labca ] || mv bin/labca bin/labca_prev

    chown -R labca:labca $baseDir
    chown root:root "$cloneDir/cron_d"

    [ -e /etc/cron.d/labca ] && rm /etc/cron.d/labca || true
    [ -e /etc/logrotate.d/labca ] && rm /etc/logrotate.d/labca || true

    git add --all &>/dev/null || true
    git commit --all --quiet -m "LabCA after update $runId" &>>$installLog || true

    msg_ok "$msg"
}

# Update any outdated packages
update_upgrade() {
    msg_info "Making sure all software is up-to-date"
    apt update &>>$installLog
    apt upgrade -y &>>$installLog
    apt autoremove -y &>>$installLog
    msg_ok "Software is up-to-date"
}

#
# Install extra packages that we rely upon
#
install_pkg() {
    local package="$1"
    msg_info "Install package '$package'"
    apt install -y "$package" &>>$installLog || msg_fatal "Could not install package '$package'"
    msg_ok "Package '$package' is installed"
}

install_extra() {
    local packages=(apt-transport-https ca-certificates curl gnupg2 net-tools software-properties-common tzdata ucspi-tcp zip python)
    for package in "${packages[@]}"; do
        install_pkg "$package"
    done

    distrib=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    curl -fsSL https://download.docker.com/linux/${distrib}/gpg 2>>$installLog | apt-key add - &>>$installLog || msg_fatal "Could not download docker repository key"
    add-apt-repository -r "deb [arch=amd64] https://download.docker.com/linux/${distrib} $(lsb_release -cs) stable" &>>$installLog
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${distrib} $(lsb_release -cs) stable" &>>$installLog
    apt update &>>$installLog
    install_pkg "docker-ce"

    # Make sure the labca user has docker permissions
    usermod -aG docker labca

    msg_info "Install binary 'docker-compose'"
    local dcver=""
    [ -x /usr/local/bin/docker-compose ] && dcver="`/usr/local/bin/docker-compose --version`"
    local vercmp=${dcver/$dockerComposeVersion/}
    if [ "$dcver" == "" ] || [ "$dcver" == "$vercmp" ]; then
        local v1test=${dcver/version 1./}
        if [ "$dcver" != "$v1test" ] && [ "$dcver" != "" ]; then
            mv /usr/local/bin/docker-compose /usr/local/bin/docker-compose-v1
        fi

        curl -sSL https://github.com/docker/compose/releases/download/$dockerComposeVersion/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose &>>$installLog || msg_fatal "Could not download docker-compose"
        chmod +x /usr/local/bin/docker-compose
    fi
    msg_ok "Binary 'docker-compose' is installed"
}

# Configure the static web pages (for end users)
static_web() {
    local rc=0

    local msg="Static web pages"
    msg_info "$msg"
    if [ -d /etc/nginx ]; then
        # Migrate cert from host nginx to dockerized nginx
        [ -d /home/labca/nginx_data/ssl ] || mkdir -p /home/labca/nginx_data/ssl
        mv /etc/nginx/ssl/* /home/labca/nginx_data/ssl/
        mv /etc/nginx /etc/nginx.backup
    fi

    [ -d /home/labca/nginx_data/conf.d ] || mkdir -p /home/labca/nginx_data/conf.d
    [ -d /home/labca/nginx_data/ssl ] || mkdir -p /home/labca/nginx_data/ssl
    cp $cloneDir/nginx.conf /home/labca/nginx_data/conf.d/labca.conf
    if [ -f "$boulderLabCADir/setup_complete" ]; then
        perl -i -p0e 's/\n    # BEGIN temporary redirect\n    location = \/ \{\n        return 302 \/admin\/;\n    }\n    # END temporary redirect\n//igs' /home/labca/nginx_data/conf.d/labca.conf
    fi

    [ -d /home/labca/nginx_data/static ] || mkdir /home/labca/nginx_data/static
    cd /home/labca/nginx_data/static
    git status --short &> /dev/null || rc=$?
    if [ $rc -gt 0 ]; then
        git init &>>$installLog
    fi
    git add --all &>/dev/null || true
    git commit --all --quiet -m "LabCA before update $runId" &>>$installLog && { msg_ok "Commit existing modifications of $adminDir"; msg_info "$msg"; } || true

    mkdir -p .well-known/acme-challenge
    find .well-known/acme-challenge/ -type f -mtime +10 -exec rm {} \;  # Clean up files older than 10 days
    mkdir -p crl
    [ -e cert ] || ln -s certs cert
    cp -rp $cloneDir/static/* .
    sed -i -e "s|\[LABCA_CPS_LOCATION\]|http://$LABCA_FQDN/cps/|g" cps/index.html
    sed -i -e "s|\[LABCA_CERTS_LOCATION\]|http://$LABCA_FQDN/certs/|g" cps/index.html

    local have_config=$(grep restarted $adminDir/data/config.json | grep true)
    if [ "$have_config" != "" ]; then
        export PKI_ROOT_CERT_BASE="$adminDir/data/root-ca"
        export PKI_INT_CERT_BASE="$adminDir/data/issuer/ca-int"
        export PKI_DEFAULT_O=$(grep organization $adminDir/data/config.json | sed -e 's/.*:[ ]*//' | sed -e 's/\",//g' | sed -e 's/\"//g')

        $adminDir/apply-nginx
    fi

    git add --all &>/dev/null || true
    git commit --all --quiet -m "LabCA after update $runId" &>>$installLog || true

    msg_ok "$msg"
}

# Create a temporary self-signed certificate if there is no certificate yet
selfsigned_cert() {
    if [ -e /home/labca/nginx_data/ssl/labca_cert.pem ]; then
        msg_ok "Certificate is present"
    else
        local msg="Create self-signed certificate"
        msg_info "$msg"
        mkdir -p /home/labca/nginx_data/ssl
        cd /home/labca/nginx_data/ssl
        openssl req -x509 -nodes -sha256 -newkey rsa:2048 -keyout labca_key.pem -out labca_cert.pem -days 7 \
            -subj "/O=LabCA/CN=$LABCA_FQDN" -reqexts SAN -extensions SAN \
            -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nbasicConstraints=CA:FALSE\nnsCertType=server\nsubjectAltName=DNS:$LABCA_FQDN")) &>>$installLog
        msg_ok "$msg"
    fi
}

# Clone or update the boulder code (Let's Encrypt (tm) implementation of ACME protocol)
get_boulder() {
    export GOPATH="/home/labca/gopath"
    sudo -u labca -H mkdir -p "$GOPATH/src/github.com/letsencrypt"
    [ -h "$boulderDir" ] || sudo -u labca -H ln -s "$GOPATH/src/github.com/letsencrypt/boulder" "$boulderDir"

    if [ -e "$boulderDir" ]; then
        cd "$boulderDir"
        git checkout -- docker-compose.yml errors/errors.go policy/pa.go
        git reset --hard &>>$installLog
    fi

    clone_or_pull "$GOPATH/src/github.com/letsencrypt/boulder" "$boulderUrl"

    cd "$boulderDir"
    sudo -u labca -H git reset --hard $boulderTag &>>$installLog
    if [ -e "sa/_db-next/migrations/20190221140139_AddAuthz2.sql" ]; then
        sudo -u labca -H cp sa/_db-next/migrations/20190221140139_AddAuthz2.sql sa/_db/migrations/
    fi
    if [ -e "sa/_db-next/migrations/20190524120239_AddAuthz2ExpiresIndex.sql" ]; then
        sudo -u labca -H cp sa/_db-next/migrations/20190524120239_AddAuthz2ExpiresIndex.sql sa/_db/migrations/
    fi
    msg_ok "Boulder checkout '$boulderTag'"
}

# Configure boulder based on their test subdirectory
config_boulder() {
    local msg="Setup boulder configuration folder"
    msg_info "$msg"

    [ -d "$boulderLabCADir" ] || mkdir -p "$boulderLabCADir"
    cd "$boulderLabCADir"
    local rc=0
    git status --short &> /dev/null || rc=$?
    if [ $rc -gt 0 ]; then
        git init &>>$installLog
    fi
    [ -d ".backup" ] || mkdir -p ".backup"

    git add --all &>/dev/null || true
    git commit --all --quiet -m "LabCA before update $runId" &>>$installLog && { msg_ok "Commit existing modifications of $boulderLabCADir"; msg_info "$msg"; } || true

    [ ! -e "$boulderLabCADir/secrets/smtp_password" ] || mv "$boulderLabCADir/secrets/smtp_password" "$boulderLabCADir/secrets/smtp_password_PRESERVE"
    cp -r "$boulderDir/test" -T "$boulderLabCADir" &>>$installLog
    [ ! -e "$boulderLabCADir/secrets/smtp_password_PRESERVE" ] || mv "$boulderLabCADir/secrets/smtp_password_PRESERVE" "$boulderLabCADir/secrets/smtp_password"
    chown -R labca:labca "$boulderLabCADir"

    rm -rf authz-filler challtestsrv gsb-test-srv

    msg_ok "$msg"
    msg="Configure the boulder application"
    msg_info "$msg"

    cd "$boulderDir"
    $cloneDir/patch.sh "sudo -u labca -H" &>>$installLog

    cp docker-compose.yml "$boulderLabCADir/.backup/"
    cp cmd/shell.go "$boulderLabCADir/.backup/"
    cp core/interfaces.go "$boulderLabCADir/.backup/"
    cp policy/pa.go "$boulderLabCADir/.backup/"
    cp ra/ra.go "$boulderLabCADir/.backup/"
    cp reloader/reloader.go "$boulderLabCADir/.backup/"
    cp mail/mailer.go "$boulderLabCADir/.backup/"
    cp cmd/expiration-mailer/main.go "$boulderLabCADir/.backup/"
    cp cmd/notify-mailer/main.go "$boulderLabCADir/.backup/"
    cp cmd/contact-auditor/main.go "$boulderLabCADir/.backup/"
    cp cmd/bad-key-revoker/main.go "$boulderLabCADir/.backup/"
    cp cmd/cert-checker/main.go "$boulderLabCADir/.backup/"
    cp cmd/log-validator/main.go "$boulderLabCADir/.backup/"
    cp cmd/boulder/main.go "$boulderLabCADir/.backup/"
    cp ratelimit/rate-limits.go "$boulderLabCADir/.backup/"
    cp errors/errors.go "$boulderLabCADir/.backup/"
    cp log/log.go "$boulderLabCADir/.backup/"
    cp sa/_db/migrations/20210223140000_CombinedSchema.sql "$boulderLabCADir/.backup/"
    cp Makefile "$boulderLabCADir/.backup/"

    sudo -u labca -H patch -p1 -o "$boulderLabCADir/entrypoint.sh" < $cloneDir/patches/entrypoint.patch &>>$installLog
    cp test/startservers.py "$boulderLabCADir/startservers.py" &>>$installLog

    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/ca-a.json" < $cloneDir/patches/test_config_ca_a.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/ca-b.json" < $cloneDir/patches/test_config_ca_b.patch &>>$installLog

    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/expiration-mailer.json" < $cloneDir/patches/config_expiration-mailer.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/notify-mailer.json" < $cloneDir/patches/config_notify-mailer.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/bad-key-revoker.json" < $cloneDir/patches/config_bad-key-revoker.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/ocsp-responder.json" < $cloneDir/patches/config_ocsp-responder.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/publisher.json" < $cloneDir/patches/config_publisher.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/wfe2.json" < $cloneDir/patches/config_wfe2.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/rocsp-tool.json" < $cloneDir/patches/config_rocsp-tool.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/orphan-finder.json" < $cloneDir/patches/config_orphan-finder.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/ra.json" < $cloneDir/patches/config_ra.patch &>>$installLog
    sudo -u labca -H patch -p1 -o "$boulderLabCADir/config/va.json" < $cloneDir/patches/config_va.patch &>>$installLog

    mkdir -p $baseDir/backup
    [ -z "$(docker ps | grep boulder-bmysql-1)" ] || docker exec -i boulder-bmysql-1 mysqldump boulder_sa_integration >$baseDir/backup/dbdata-${runId}.sql
    # housekeeping
    for file in `ls -1t $baseDir/backup/dbdata-*.sql 2>&1 | tail -n +3 || true`; do
        rm $file
    done

    cd "$boulderLabCADir"
    sed -i -e "s/test-ca2.pem/test-ca.pem/" config/ocsp-responder.json
    sed -i -e "s/test-ca2.pem/test-ca.pem/" config/ocsp-updater.json
    sed -i -e "s/test-ca2.pem/test-ca.pem/" config/publisher.json
    sed -i -e "s/test-ca2.pem/test-ca.pem/" config/ra.json
    sed -i -e "s/test-ca2.pem/test-ca.pem/" config/wfe2.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/akamai-purger.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/ocsp-responder.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/ocsp-updater.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/publisher.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/ra.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/wfe2.json
    sed -i -e "s|.hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/rocsp-tool.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/orphan-finder.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" config/ra.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" issuer-ocsp-responder.json
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" cert-ceremonies/intermediate-ocsp-rsa.yaml
    sed -i -e "s|/hierarchy/intermediate-cert-rsa-a.pem|labca/test-ca.pem|" v2_integration.py
    sed -i -e "s|/hierarchy/root-cert-rsa.pem|labca/test-root.pem|" cert-ceremonies/root-ceremony-rsa.yaml
    sed -i -e "s|/hierarchy/root-cert-rsa.pem|labca/test-root.pem|" cert-ceremonies/intermediate-ocsp-rsa.yaml
    sed -i -e "s|/hierarchy/root-cert-rsa.pem|labca/test-root.pem|" cert-ceremonies/intermediate-ceremony-rsa.yaml
    sed -i -e "s|/hierarchy/root-cert-rsa.pem|labca/test-root.pem|" config/publisher.json
    sed -i -e "s|/hierarchy/root-cert-rsa.pem|labca/test-root.pem|" config/wfe2.json
    sed -i -e "s|/hierarchy/root-cert-rsa.pem|labca/test-root.pem|" integration-test.py
    sed -i -e "s|/hierarchy/root-cert-rsa.pem|labca/test-root.pem|" helpers.py
    sed -i -e "s/5001/443/g" config/va.json
    sed -i -e "s/5002/80/g" config/va.json
    sed -i -e "s/5001/443/g" config/va-remote-a.json
    sed -i -e "s/5002/80/g" config/va-remote-a.json
    sed -i -e "s/5001/443/g" config/va-remote-b.json
    sed -i -e "s/5002/80/g" config/va-remote-b.json
    sed -i -e "s|https://boulder:4431/terms/v7|https://$LABCA_FQDN/terms/v1|" config/wfe2.json
    sed -i -e "s|http://boulder:4430/acme/issuer-cert|http://$LABCA_FQDN/certs/ca-int.der|" config/ca-a.json
    sed -i -e "s|http://boulder:4430/acme/issuer-cert|http://$LABCA_FQDN/certs/ca-int.der|" config/ca-b.json
    sed -i -e "s|http://127.0.0.1:4000/acme/issuer-cert|http://$LABCA_FQDN/certs/ca-int.der|" config/ca-a.json
    sed -i -e "s|http://127.0.0.1:4000/acme/issuer-cert|http://$LABCA_FQDN/certs/ca-int.der|" config/ca-b.json
    sed -i -e "s|http://boulder:4430/acme/issuer-cert|http://$LABCA_FQDN/acme/issuer-cert|" config/wfe2.json
    sed -i -e "s|http://127.0.0.1:4000/acme/issuer-cert|https://$LABCA_FQDN/acme/issuer-cert|" config/wfe2.json
    sed -i -e "s|letsencrypt/boulder|hakwerk/labca|" config/wfe2.json
    sed -i -e "s|http://127.0.0.1:4002/|http://$LABCA_FQDN/ocsp/|g" config/ca-a.json
    sed -i -e "s|http://127.0.0.1:4002/|http://$LABCA_FQDN/ocsp/|g" config/ca-b.json
    sed -i -e "s|http://example.com/cps|http://$LABCA_FQDN/cps/|g" config/ca-a.json
    sed -i -e "s|http://example.com/cps|http://$LABCA_FQDN/cps/|g" config/ca-b.json
    sed -i -e "s|1.2.3.4|1.3.6.1.4.1.44947.1.1.1|g" config/ca-a.json
    sed -i -e "s|1.2.3.4|1.3.6.1.4.1.44947.1.1.1|g" config/ca-b.json
    perl -i -p0e "s/(\s+\"crlURL\":[^\n]*)//igs" config/ca-a.json
    perl -i -p0e "s/(\s+\"crlURL\":[^\n]*)//igs" config/ca-b.json
    sed -i -e "s/Do What Thou Wilt/This PKI is only meant for internal (lab) usage; do NOT use this on the open internet\!/g" config/ca-a.json
    sed -i -e "s/Do What Thou Wilt/This PKI is only meant for internal (lab) usage; do NOT use this on the open internet\!/g" config/ca-b.json
    sed -i -e "s/ocspURL.Path = encodedReq/ocspURL.Path += encodedReq/" ocsp/helper/helper.go
    sed -i -e "s/\"dnsTimeout\": \".*\"/\"dnsTimeout\": \"3s\"/" config/ra.json
    sed -i -e "s/\"dnsTimeout\": \".*\"/\"dnsTimeout\": \"3s\"/" config/va.json
    sed -i -e "s/\"dnsTimeout\": \".*\"/\"dnsTimeout\": \"3s\"/" config/va-remote-a.json
    sed -i -e "s/\"dnsTimeout\": \".*\"/\"dnsTimeout\": \"3s\"/" config/va-remote-b.json

    if [ "$flag_skip_redis" == true ]; then
        sed -i -e "s/^\(.*wait-for-it.sh.*4218\)/#\1/" entrypoint.sh
    fi

    for file in `find . -type f | grep -v .git`; do
        sed -i -e "s|test/|labca/|g" $file
    done

    sed -i -e "s/names/name\(s\)/" example-expiration-template

    rm test-ca2.pem
    ([ -e mock-vendor.go ] && rm mock-vendor.go) || /bin/true
    ([ -e test-tools.go ] && rm test-tools.go) || /bin/true

    local have_config=$(grep restarted $adminDir/data/config.json | grep true)
    if [ "$have_config" != "" ]; then
        export PKI_ROOT_CERT_BASE="$adminDir/data/root-ca"
        export PKI_INT_CERT_BASE="$adminDir/data/issuer/ca-int"
        export PKI_DNS=$(grep dns $adminDir/data/config.json | perl -p0e 's/.*?:\s+(.*)/\1/' | sed -e 's/\",//g' | sed -e 's/\"//g')
        export PKI_FQDN=$(grep fqdn $adminDir/data/config.json | sed -e 's/.*:[ ]*//' | sed -e 's/\",//g' | sed -e 's/\"//g')
        export PKI_DOMAIN=$(echo $PKI_FQDN | perl -p0e 's/.*?\.//')
        export PKI_DOMAIN_MODE=$(grep domain_mode $adminDir/data/config.json | sed -e 's/.*:[ ]*//' | sed -e 's/\",//g' | sed -e 's/\"//g')
        export PKI_LOCKDOWN_DOMAINS=$(grep lockdown $adminDir/data/config.json | grep -v domain_mode | sed -e 's/.*:[ ]*//' | sed -e 's/\",//g' | sed -e 's/\"//g')
        export PKI_WHITELIST_DOMAINS=$(grep whitelist $adminDir/data/config.json | grep -v domain_mode | sed -e 's/.*:[ ]*//' | sed -e 's/\",//g' | sed -e 's/\"//g')

        enabled=$(grep "email\": {" $adminDir/data/config.json -A1 | grep enable | head -1 | perl -p0e 's/.*?:\s+(.*)/\1/' | sed -e 's/\",//g' | sed -e 's/\"//g')
        if [ "$enabled" == "true," ]; then
            export PKI_EMAIL_SERVER=$(grep server $adminDir/data/config.json | head -1 | perl -p0e 's/.*?:\s+(.*)/\1/' | sed -e 's/\",//g' | sed -e 's/\"//g')
            export PKI_EMAIL_PORT=$(grep port $adminDir/data/config.json | head -1 | perl -p0e 's/.*?:\s+(.*)/\1/' | sed -e 's/\",//g' | sed -e 's/\"//g')
            export PKI_EMAIL_USER=$(grep user $adminDir/data/config.json | head -1 | perl -p0e 's/.*?:\s+(.*)/\1/' | sed -e 's/\",//g' | sed -e 's/\"//g')
            export PKI_EMAIL_FROM=$(grep from $adminDir/data/config.json | head -1 | perl -p0e 's/.*?:\s+(.*)/\1/' | sed -e 's/\",//g' | sed -e 's/\"//g')
        else
            export PKI_EMAIL_SERVER="localhost"
            export PKI_EMAIL_PORT="9380"
            export PKI_EMAIL_USER="cert-manager@example.com"
            export PKI_EMAIL_FROM="Expiry bot <test@example.com>"
        fi

        local extended_timeout=$(grep extended_timeout $adminDir/data/config.json | grep true)
        if [ "$extended_timeout" != "" ]; then
            export PKI_EXTENDED_TIMEOUT=1
        fi

        $adminDir/apply-boulder &>>$installLog
    else
        chown -R labca:labca "$boulderLabCADir"
    fi

    git add --all &>/dev/null || true
    git commit --all --quiet -m "LabCA after update $runId" &>>$installLog || true

    msg_ok "$msg"
}

# Cleanup any now obsolete files
cleanup() {
    local msg="Cleaning up obsolete files"
    msg_info "$msg"

    if [ -d /var/www/html ]; then
        rm -f /var/www/html/css/skeleton.css
        rm -f /var/www/html/css/skeleton-tabs.css
        rm -f /var/www/html/css/normalize.css
        rm -f /var/www/html/css/font.css
        rm -f /var/www/html/img/favicon.ico
        rm -f /var/www/html/js/jquery-3.3.1.min.js
        rm -f /var/www/html/js/skeleton-tabs.js
    fi
    rm -f $adminDir/templates/cert.tmpl
    rm -f $adminDir/templates/error.tmpl
    rm -f $adminDir/templates/final.tmpl
    rm -f $adminDir/templates/footer.tmpl
    rm -f $adminDir/templates/header.tmpl
    rm -f $adminDir/templates/index.tmpl
    rm -f $adminDir/templates/login.tmpl
    rm -f $adminDir/templates/polling.tmpl
    rm -f $adminDir/templates/register.tmpl
    rm -f $adminDir/templates/setup.tmpl
    rm -f $adminDir/templates/wrapup.tmpl

    # Remove host nginx if installed, as we are now using the docker container
    systemctl stop nginx &>>$installLog || true
    systemctl disable nginx &>>$installLog || true
    apt remove -y nginx &>>$installLog

    msg_ok "$msg"
}

# Startup all the components
startup() {
    local msg="Restart docker containers and service"

    cd "$boulderDir"
    cnt=$(docker-compose ps | wc -l)
    if [ "$cnt" == "2" ]; then
        msg="Download docker images and build containers"
    fi
    msg_info "$msg (this will take a while!!)"

    docker-compose pull -q &>>$installLog
    docker-compose stop boulder bmysql labca nginx &>>$installLog || true
    for ct in boulder_bhsm_1 boulder_bredis_1 boulder_bredis_2 boulder_bredis_3 boulder_bredis_4 boulder_bredis_5 boulder_bredis_6; do
        [ -z "$(docker ps | grep $ct)" ] || docker stop $ct &>>$installLog
    done
    wait_down $PS_MYSQL &>>$installLog || true
    wait_down $PS_LABCA &>>$installLog || true
    wait_down $PS_BOULDER &>>$installLog || true
    for ct in boulder_bhsm_1 boulder_bredis_1 boulder_bredis_2 boulder_bredis_3 boulder_bredis_4 boulder_bredis_5 boulder_bredis_6; do
        [ -z "$(docker ps -a | grep -e "$ct\$")" ] || docker rm -f $ct &>>$installLog
    done

    service labca stop &>>$installLog || true
    update-rc.d labca disable &>>$installLog || true
    [ -e "/etc/init.d/labca" ] && rm /etc/init.d/labca || true

    COMPOSE_HTTP_TIMEOUT=120 docker-compose up -d &>>$installLog

    wait_up $PS_MYSQL &>>$installLog || true
    wait_up $PS_LABCA &>>$installLog || true
    wait_up $PS_SERVICE &>>$installLog || true
    docker exec -i boulder-bmysql-1 mysql_upgrade &>>$installLog
    [ -f "$boulderLabCADir/setup_complete" ] && wait_up $PS_BOULDER $PS_BOULDER_COUNT &>>$installLog || /bin/true

    COMPOSE_HTTP_TIMEOUT=120 docker-compose restart control &>>$installLog

    msg_ok "$msg"
}

# If the nginx certificate is self-signed then show extra text
first_time() {
    local certFile="/home/labca/nginx_data/ssl/labca_cert.pem"
    [ -e "$certFile" ] || msg_fatal "The SSL certificate $certFile does not exist"

    local subject=$(openssl x509 -noout -in "$certFile" -subject_hash)
    local issuer=$(openssl x509 -noout -in "$certFile" -issuer_hash)

    if [ "$subject" == "$issuer" ]; then
        echo
        echo ========
        echo
        echo "Congratulations! LabCA is now installed and should be available at https://$LABCA_FQDN"
        echo "Please go there now to finish the setup. Note that a TEMPORARY (7 days) self-signed certificate"
        echo "is used; as part of the setup verification a new certificate will be issued."
        echo
    fi
}

#
# The actual main function to tie it all together
#
main() {
    local curdir="$PWD"

    echo
    start_temporary_log
    check_root
    install_pkg "git"
    install_pkg "sudo"
    labca_user
    end_temporary_log

    this=$0
    [ -e $this ] || this="$curdir/$0"
    curChecksum=$(md5sum $this 2>/dev/null | cut -d' ' -f1)
    [ ! -e "$cloneDir/cron_d" ] || chown labca:labca "$cloneDir/cron_d"

    parse_cmdline "$@"
    if [ $keepLocal -eq 0 ]; then
        clone_or_pull "$cloneDir" "$labcaUrl" "$cmdlineBranch"
        checkout_release "$cmdlineBranch"
        restart_if_updated
    fi

    get_fqdn
    copy_admin

    update_upgrade
    install_extra

    static_web
    selfsigned_cert

    get_boulder
    config_boulder

    cleanup
    startup

    echo -e "$DONE"
    echo

    first_time

    cd "$curdir"
}

main "$@"
