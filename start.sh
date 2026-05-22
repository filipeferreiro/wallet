#!/bin/bash

set -e

# Executa script de deploy (migrations, seeds, permissões)
bash deploy.sh

# Verifica helper Apache em vendor/bin ou no PATH antes de executar
APACHE_HELPER=""

if [ -x "vendor/bin/heroku-php-apache2" ]; then
  APACHE_HELPER="vendor/bin/heroku-php-apache2"
else
  if command -v heroku-php-apache2 >/dev/null 2>&1; then
    APACHE_HELPER=$(command -v heroku-php-apache2)
  fi
fi

if [ -n "$APACHE_HELPER" ]; then
  echo "Starting Apache helper: $APACHE_HELPER"
  exec "$APACHE_HELPER" public/
else
  echo "Apache helper not found, using PHP built-in server"
  PORT=${PORT:-8080}
  exec php -S 0.0.0.0:${PORT} -t public
fi
