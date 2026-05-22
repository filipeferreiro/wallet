# Multi-stage Dockerfile for Laravel + Vite + SQLite

# ---- Builder stage: instalador de dependências, build de assets e vendor ----
FROM php:8.2-cli AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git curl zip unzip build-essential pkg-config libzip-dev libpng-dev libonig-dev libsqlite3-dev sqlite3 ca-certificates gnupg && \
    rm -rf /var/lib/apt/lists/*

# Instala Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

# Instala Composer no builder
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copia dependências PHP e instala (no builder)
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --prefer-dist --no-interaction --no-scripts
RUN composer dump-autoload --optimize --no-scripts

# Copia fontes do frontend e builda assets
COPY package.json package-lock.json vite.config.js ./
COPY resources resources
RUN npm install --legacy-peer-deps
RUN npm run build

# Copia restante da aplicação para incluir migrations/seeders, etc.
COPY . .

# Garante autoload e assets prontos
RUN composer dump-autoload --optimize --no-scripts || true


# ---- Final stage: runtime enxuto ----
FROM php:8.2-fpm

# Instala apenas dependências necessárias para correr extensões (sqlite) e runtime
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libpng-dev libonig-dev libsqlite3-0 libsqlite3-dev ca-certificates && rm -rf /var/lib/apt/lists/*

# Compila e habilita extensões necessárias (PDO SQLite, mbstring, bcmath, zip)
RUN docker-php-ext-install pdo pdo_sqlite mbstring bcmath zip || true

# Copia composer do stage oficial (runtime também precisa do binário)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copia código pronto do builder para o runtime
COPY --from=builder /app /var/www/html

# Ajustes de permissão e arquivos runtime
RUN chown -R www-data:www-data /var/www/html || true
RUN chmod +x /var/www/html/start.sh || true

EXPOSE 8080

CMD ["bash", "start.sh"]