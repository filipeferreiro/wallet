#!/bin/bash

set -euo pipefail

# Cria o arquivo do banco SQLite se ele não existir
mkdir -p database
touch database/database.sqlite

# Limpa caches antigos
php artisan config:clear || true
php artisan route:clear || true

# Se não houver dependências instaladas, instala (útil em ambientes de runtime)
if [ ! -d "vendor" ]; then
	composer install --no-dev --optimize-autoloader --prefer-dist --no-interaction
fi

# Regenera o mapa de classes do PHP para garantir que novos Seeders/Models sejam encontrados
composer dump-autoload --optimize

# Executa as migrations e o seeder com a classe totalmente qualificada para evitar problemas
php artisan migrate --force
php artisan db:seed --class="Database\\Seeders\\DatabaseSeeder" --no-interaction

# Otimiza os caches novamente para produção
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo "Deploy script completed successfully." 