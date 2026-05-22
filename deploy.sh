#!/bin/bash

# Cria o arquivo do banco SQLite se ele não existir
touch database/database.sqlite

# Otimiza o cache do Laravel
php artisan config:cache
php artisan route:cache
php artisan view:cache

# CORREÇÃO: Executa as migrations usando a flag correta e roda os seeders
php artisan migrate --force --seed