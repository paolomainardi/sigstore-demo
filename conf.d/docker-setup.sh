#!/bin/sh
echo "opcache.enable=0" >> /usr/local/etc/php/conf.d/opcache-recommended.ini
rm -rf vendor && composer install

# Install jless.
apt-get -y install unzip libxcb-render-util0
ARCH=$(uname -m)
curl -sSL https://github.com/PaulJuliusMartinez/jless/releases/download/v0.9.0/jless-v0.9.0-${ARCH}-unknown-linux-gnu.zip -o /tmp/jless.zip
unzip /tmp/jless.zip -d /tmp
mv /tmp/jless /usr/local/bin/jless
chmod +x /usr/local/bin/jless

# Clean apt caches.
apt-get -y remove unzip && \
apt-get clean && \
    rm -rf /var/lib/apt/lists/