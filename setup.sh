#!/bin/bash

# Check if an IP address is passed as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <IP_ADDRESS>"
    exit 1
fi

IP_ADDRESS=$1

# Update package lists
sudo apt-get update

# Upgrade installed packages (optional, uncomment if needed)
# sudo apt-get upgrade -y

# Install BIND9 and necessary packages
sudo apt-get install -y bind9 bind9utils bind9-doc

# Backup original BIND configuration files
sudo cp /etc/bind/named.conf /etc/bind/named.conf.backup
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup

# Set up BIND configuration
echo "Writing named.conf.local and named.conf.options..."
sudo tee /etc/bind/named.conf.local > /dev/null <<EOF
zone "example.com" {
    type master;
    file "/etc/bind/zones/db.example.com";
};
zone "facebook.com" {
    type master;
    file "/etc/bind/zones/db.facebook.com";
};
zone "vercara.com" {
    type master;
    file "/etc/bind/zones/db.vercara.com";
};
zone "test.local" {
    type master;
    file "/etc/bind/zones/db.test.local";
};
zone "zxit183472.biz" {
    type master;
    file "/etc/bind/zones/db.zxit183472.biz";
};
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
for domain in example.com facebook.com vercara.com test.local zxit183472.biz; do
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

# Install Nginx and configure web page
sudo apt-get install -y nginx
echo "<html><body><h1>DDR Boot Camp Test</h1></body></html>" | sudo tee /var/www/html/index.html

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

