#!/bin/sh
docker-compose exec drupal mkdir -p /opt/drupal/web/sqlite
docker-compose exec drupal drush si -y \
                --account-pass=admin \
                --db-url=sqlite://sqlite/db
docker-compose exec drupal chmod -R ugo+w /opt/drupal/web/sqlite