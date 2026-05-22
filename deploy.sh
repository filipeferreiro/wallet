#!/# !/bin/bash

# Instala dependências do PHP de forma otimizada para produção
composer install --no-dev --optimize-autoloader

# Instala dependências do Node e compila os assets do Vue 3 via Vite
npm install
npm run build

# Otimiza o cache do Laravel
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Cria o arquivo do banco SQLite caso ele não exista em produção
touch database/database.sqlite

# Executa as migrations e popula o banco com o usuário de teste (seeder)
php artisan migrate:force --seed