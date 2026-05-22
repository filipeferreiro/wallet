# Multi-stage-like single Dockerfile for Laravel + Vite + SQLite
FROM php:8.2-fpm

# Instala dependências do sistema e extensões PHP necessárias
RUN apt-get update && apt-get install -y \
    git curl zip unzip libzip-dev libpng-dev libonig-dev sqlite3 libsqlite3-dev ca-certificates gnupg \
  && docker-php-ext-install pdo pdo_sqlite mbstring zip bcmath \
  && rm -rf /var/lib/apt/lists/*

# Instala Composer (copia do container oficial do Composer)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Instala Node.js (Node 18) e npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
  && apt-get install -y nodejs \
  && npm --version || true \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copia apenas os arquivos de dependências e instala dependências PHP
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --prefer-dist --no-interaction --no-scripts || true
RUN composer dump-autoload --optimize --no-scripts || true

# Copia package files e builda assets
COPY package.json package-lock.json vite.config.js ./
COPY resources resources
RUN npm install --legacy-peer-deps || true
RUN npm run build || true

# Copia o restante da aplicação
COPY . .

# Permissões e artefatos finais
RUN chown -R www-data:www-data /var/www/html || true
RUN chmod +x start.sh || true

EXPOSE 8080

CMD ["bash", "start.sh"]
FROM php:8.2-fpm

# Instala dependências do sistema e extensões comuns
RUN apt-get update && apt-get install -y \
    git unzip curl zip libzip-dev libpng-dev libonig-dev nodejs npm \
    && docker-php-ext-install pdo pdo_sqlite

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copia projeto e instala dependências
COPY . /var/www/html
RUN composer install --no-dev --optimize-autoloader --prefer-dist --no-interaction --no-scripts
RUN composer dump-autoload --optimize --no-scripts

# Frontend
RUN npm install
RUN npm run build

# Permissões e build final
RUN php artisan key:generate --no-interaction || true
RUN chown -R www-data:www-data /var/www/html
RUN chmod +x start.sh

EXPOSE 8080
CMD ["bash", "start.sh"]