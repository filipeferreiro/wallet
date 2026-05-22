#!/bin/bash

# Executa script de deploy (migrations, seeds, permissões)
bash deploy.sh

# Se existir o helper do Heroku para iniciar Apache, usa ele; caso contrário, fallback para PHP built-in server
if [ -f "vendor/bin/heroku-php-apache2" ]; then
  exec vendor/bin/heroku-php-apache2 public/
else
  # Porta padrão esperada: 8080
  PORT=${PORT:-8080}
  exec php -S 0.0.0.0:${PORT} -t public
fi
