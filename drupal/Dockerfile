FROM drupal:10.0.9-php8.1-fpm-alpine3.18

LABEL org.opencontainers.image.source=https://github.com/paolomainardi/sigstore-demo

# Install firebase tools, needed to store the assets.
RUN apk add --no-cache nodejs npm && \
    npm install -g firebase-tools

# Install drupal dependencies.
RUN composer require drupal/metatag:^1.25 \
                     drupal/paragraphs:^1.15 \
                     drupal/admin_toolbar:^3.4 \
                     drupal/s3fs:^3.3

