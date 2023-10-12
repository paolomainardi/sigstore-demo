#!/bin/sh
echo "opcache.enable=0" >> /usr/local/etc/php/conf.d/opcache-recommended.ini
rm -rf vendor && composer install