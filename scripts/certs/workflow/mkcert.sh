mkcert -install

mkcert -CAROOT

ls ~/.local/share/mkcert

mkcert kifarunix-demo.com '*.kifarunix-demo.com' localhost 127.0.0.1 ::1

ls -1 ./kifarunix-demo.com+*

# To configure Apache to use these certificates,
# edit the default ssl configuration file, 
# /etc/apache2/sites-available/default-ssl.conf and change the 
# SSL certificate and key file to point to the locally generated cert and key file above.

# Be sure to replace the paths accordingly
sudo sed -i \
's#/etc/ssl/certs/ssl-cert-snakeoil.pem#/home/koromicha/kifarunix-demo.com+4.pem#; \
s#/etc/ssl/private/ssl-cert-snakeoil.key#/home/koromicha/kifarunix-demo.com+4-key.pem#' \
/etc/apache2/sites-available/default-ssl.conf

# to verify
grep -E "SSLCertificateFile|SSLCertificateKeyFile" /etc/apache2/sites-available/default-ssl.conf

# Enable Apache to use SSL by loading the ssl modules;

sudo a2enmod ssl
sudo a2ensite default-ssl.conf

#Reload and restart Apache to activate the new configuration

sudo systemctl restart apache2

#Verify Local SSL Certs generated with mkcert
#Navigate to the browser and try to access your domain.

#I am using local hosts file for my DNS
#Enable the Certificates for Nginx Web Server
#Create your web page configuration as shown below.

# Replace the paths to the ceritificate and key accordingly

vim /etc/nginx/sites-available/example.com
server {
listen 80;
listen 443 ssl;

ssl on;
ssl_certificate /home/koromicha/kifarunix-demo.com+4.pem; 
ssl_certificate_key /home/koromicha/kifarunix-demo.com+4-key.pem;

server_name example.com;
location / {
root /var/www/html/example;
index index.html;
}
}


#Verify that the configuration has no error.

nginx -t
#nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
#nginx: configuration file /etc/nginx/nginx.conf test is successful

#Restart Nginx
systemctl restart nginx

#Navigate to the browser and test your ssl for your domain.

#And that concludes our guide on how to create locally trusted SSL certificates with mkcert on Ubuntu 20.04.

# More mkcert usage information.

mkcert --help
