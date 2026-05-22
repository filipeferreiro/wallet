#!/bin/bash

# Fail fast on errors
set -e

# 1) Determina caminho do SQLite a partir da variável de ambiente, com fallback
DB_PATH="${DB_DATABASE:-database/database.sqlite}"

# Cria pasta e arquivo do banco imediatamente (suporta volume montado em /app/database)
mkdir -p "$(dirname "$DB_PATH")"
touch "$DB_PATH"

# Garante permissões básicas para que o processo web consiga escrever no SQLite e caches
chmod 0666 "$DB_PATH" || true
chmod -R 0777 storage bootstrap/cache || true

# 2) Limpa caches antigos antes de qualquer outra ação (evita usar caches quebrados do build anterior)
php artisan config:clear || true
php artisan route:clear || true
php artisan view:clear || true

# 3) Instala dependências PHP caso necessário (em produção preferir já ter vendor no build)
if [ ! -d "vendor" ]; then
  composer install --no-dev --optimize-autoloader --prefer-dist --no-interaction --no-scripts
fi

# 4) Regenera o autoload do Composer sem executar scripts para evitar hooks que leiam configuração
composer dump-autoload --optimize --no-scripts

# 5) Executa migrations (forçando) e depois o seeder com a classe totalmente qualificada
php artisan migrate --force
php artisan db:seed --class="Database\\Seeders\\DatabaseSeeder" --no-interaction || true

# 6) Reaplica permissões após criar arquivos pelo framework
chmod 0666 "$DB_PATH" || true
chmod -R 0777 storage bootstrap/cache || true

# Garante start.sh executável (importante no ambiente Railway)
chmod +x start.sh || true

# 7) Otimiza caches para produção (falha silenciosa se algum cache não puder ser gerado)
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo "Deploy script completed successfully." 