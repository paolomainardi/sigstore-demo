FROM drupal:10.1.5-apache-bullseye

# Install firebase tools, needed to store the assets.
RUN apt-get update && \
    apt-get install -y nodejs npm vim && \
    npm install -g firebase-tools

# Install drupal dependencies.
RUN composer require drupal/webprofiler:^10.1 \
                     drupal/paragraphs:^1.16 \
                     drupal/s3fs:^3.3 \
                     drush/drush:^12

# Install syft.
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install grype.
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
ENV PATH="/opt/drupal/vendor/bin:${PATH}"

# Finish setup.
COPY conf.d/docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup && \
    docker-setup

