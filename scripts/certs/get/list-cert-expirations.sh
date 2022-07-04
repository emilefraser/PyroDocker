#!/bin/bash
printf "%-50s | %-25s\n" "SITE" "EXPIRES"
echo "-------------------------------------------------------------------"
for site in `grep -hR "ssl_certificate /etc/nginx/" /etc/nginx/sites-enabled/|awk '/ssl_certificate/ {print $2}'`; do
  sitename="$(echo $site | awk -F/ '{print $5}')"
  expire="$(sudo openssl x509 -enddate -noout -in ${site::-1}|awk -F= '/notAfter=/ {print $2}')"
  printf "%-50s | %-25s\n" "$sitename" "$expire"
done