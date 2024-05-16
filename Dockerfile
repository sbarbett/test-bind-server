# Use an official Ubuntu base image
FROM ubuntu:20.04

# Set non-interactive installation to avoid getting stuck asking for geographic area
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages including supervisor for managing processes
RUN apt-get update && apt-get install -y \
    bind9 \
    bind9utils \
    bind9-doc \
    nginx \
    jq \
    dnsutils \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files into the container
COPY config.json /config.json

# Read configuration from JSON file and setup BIND and nginx accordingly
RUN IP_ADDRESS=$(jq -r '.ip' /config.json) \
    && DOMAINS=$(jq -r '.domains[]' /config.json) \
    && SPLASH_TEXT=$(jq -r '.splash_text' /config.json) \
    && mkdir -p /etc/bind/zones \
    && chown bind:bind /etc/bind/zones \
    && cp /etc/bind/named.conf /etc/bind/named.conf.backup \
    && cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup \
    && cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup \
    && echo "options { directory \"/var/cache/bind\"; recursion no; allow-query { any; }; listen-on { any; }; };" > /etc/bind/named.conf.options \
    && echo "$DOMAINS" | while read domain; do \
       echo "zone \"$domain\" { type master; file \"/etc/bind/zones/db.$domain\"; };" >> /etc/bind/named.conf.local; \
       echo "\$TTL 604800\n@ IN SOA ns1.$domain. admin.$domain. ( \
2023051501 ; Serial\n \
604800 ; Refresh\n \
86400 ; Retry\n \
2419200 ; Expire\n \
604800 ) ; Negative Cache TTL\n@ IN NS ns1.$domain.\nns1 IN A $IP_ADDRESS\n@ IN A $IP_ADDRESS\nwww IN A $IP_ADDRESS" > /etc/bind/zones/db.$domain; \
    done \
    && echo "<html><body><h1>$SPLASH_TEXT</h1></body></html>" > /var/www/html/index.html

# Create the supervisord configuration file
RUN echo "[supervisord]" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "[program:named]" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "command=named -g" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "[program:nginx]" >> /etc/supervisor/conf.d/supervisord.conf \
    && echo "command=nginx -g 'daemon off;'" >> /etc/supervisor/conf.d/supervisord.conf

# Open necessary ports
EXPOSE 53/udp 53/tcp 80/tcp

# Start services using supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

