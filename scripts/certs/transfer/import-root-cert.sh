sudo mkdir /usr/local/share/ca-certificates/extra
sudo cp root.cert.pem /usr/local/share/ca-certificates/extra/root.cert.crt
sudo update-ca-certificates
