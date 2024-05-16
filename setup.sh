#!/bin/bash

# Update package lists
sudo apt-get update

# Install jq for JSON parsing and BIND9 and Nginx for server setup
sudo apt-get install -y jq bind9 bind9utils bind9-doc nginx

# Backup original BIND configuration files
sudo cp /etc/bind/named.conf /etc/bind/named.conf.backup
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup

# Read configuration from JSON file
IP_ADDRESS=$(jq -r '.ip' config.json)
DOMAINS=$(jq -r '.domains[]' config.json)
SPLASH_TEXT=$(jq -r '.splash_text' config.json)

# Set up BIND configuration
echo "Writing named.conf.local and named.conf.options..."
sudo tee /etc/bind/named.conf.local > /dev/null <<EOF
$(for domain in $DOMAINS; do
echo "zone \"$domain\" {
    type master;
    file \"/etc/bind/zones/db.$domain\";
};"
done)
EOF

sudo tee /etc/bind/named.conf.options > /dev/null <<EOF
options {
    directory "/var/cache/bind";
    recursion no;
    allow-query { any; };
    listen-on { any; };
};
EOF

# Create directory for zones and set permissions
sudo mkdir -p /etc/bind/zones
sudo chown bind:bind /etc/bind/zones

# Create zone files
echo "Creating zone files..."
for domain in $DOMAINS; do
    sudo tee /etc/bind/zones/db.$domain > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     ns1.$domain. admin.$domain. (
                             2023051501  ; Serial
                             604800      ; Refresh
                             86400       ; Retry
                             2419200     ; Expire
                             604800 )    ; Negative Cache TTL
;
@       IN      NS      ns1.$domain.
ns1     IN      A       $IP_ADDRESS
@       IN      A       $IP_ADDRESS
www     IN      A       $IP_ADDRESS
EOF
done

# Configure web page with custom splash text
echo "<html><body><h1>$SPLASH_TEXT</h1></body></html>" | sudo tee /var/www/html/index.html

# Configure firewall
sudo ufw allow 53
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
yes | sudo ufw enable

# Restart services
echo "Restarting services..."
sudo systemctl restart bind9
sudo systemctl restart nginx

echo "Setup completed."