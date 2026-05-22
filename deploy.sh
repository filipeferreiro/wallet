#!/bin/bash

# Cria o arquivo do banco SQLite se ele não existir
touch database/database.sqlite

# Limpa configurações antigas que possam estar presas no cache
php artisan config:clear
php artisan route:clear

# Regenera o mapa de classes do PHP para garantir que novos Seeders/Models sejam encontrados
composer dump-autoload --optimize

# Otimiza os caches novamente para produção
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Executa as migrations e os seeders com segurança
php artisan migrate --force --seed