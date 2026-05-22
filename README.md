# 💰 Wallet - Carteira Digital

![Laravel](https://img.shields.io/badge/Laravel-12.0-FF2D20?style=flat-square&logo=laravel)
![Vue.js](https://img.shields.io/badge/Vue.js-3.5-4FC08D?style=flat-square&logo=vue.js)
![PHP](https://img.shields.io/badge/PHP-8.2+-777BB4?style=flat-square&logo=php)
![SQLite](https://img.shields.io/badge/SQLite-3-003B57?style=flat-square&logo=sqlite)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## 📱 Descrição do Projeto e Decisões Técnicas Relevantes

### Visão Geral do MVP

A **Wallet** é uma aplicação de carteira digital full-stack desenvolvida com **Laravel 10+** e **Vue 3**, projetada para demonstrar boas práticas em arquitetura de software, segurança em operações financeiras e testes automatizados robustos.

O MVP oferece funcionalidades essenciais para gerenciamento de saldo:
- 💳 **Depósitos e Saques** com validação de integridade monetária
- 📊 **Dashboard** com saldo atual e métricas do mês
- 📝 **Histórico de Transações** com filtros por tipo (crédito/débito)
- 🔐 **Autenticação Segura** via Laravel Sanctum com JWT

---

### 🏗️ Arquitetura em Camadas

A aplicação segue uma arquitetura de **3 camadas bem definidas** que asseguram separação de responsabilidades, testabilidade e manutenibilidade:

#### **1. Camada HTTP (Controllers)**
- **Arquivo**: `app/Http/Controllers/WalletController.php`
- **Responsabilidade**: Gerenciar requisições/respostas HTTP e orquestração de lógica
- **Características**:
  - Controllers finos e focados em serialização de dados
  - Roteamento de requisições para camada de serviço
  - Tratamento de exceções com respostas HTTP apropriadas (200, 422)
  - Injeção de dependência do `WalletService`

```php
public function deposit(DepositRequest $request): JsonResponse
{
    $wallet = $this->getOrCreateUserWallet($request);
    try {
        $updatedWallet = $this->walletService->deposit($wallet, $request->validated()['amount']);
        return response()->json(['message' => 'Depósito realizado com sucesso!', 'balance' => $updatedWallet->balance], 200);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 422);
    }
}
```

#### **2. Camada de Validação (Form Requests)**
- **Arquivos**: `app/Http/Requests/DepositRequest.php` e `WithdrawRequest.php`
- **Responsabilidade**: Validar dados de entrada ANTES de atingir a lógica de negócio
- **Características**:
  - Validação de presença (`required`)
  - Validação de tipo (`numeric`)
  - Validação de domínio (`gt:0` - maior que zero)
  - **Validação de Precisão Monetária**: Regex `^\d+(\.\d{1,2})?$` garante **máximo 2 casas decimais**
  - Mensagens de erro customizadas em português

```php
'amount' => ['required', 'numeric', 'gt:0', 'regex:/^\d+(\.\d{1,2})?$/'],
```

#### **3. Camada de Negócio (Service Pattern)**
- **Arquivo**: `app/Services/WalletService.php`
- **Responsabilidade**: Encapsular regras de negócio, validações e operações atômicas
- **Características**:
  - **Transações Atômicas**: `DB::transaction()` garante consistência ACID
  - **Pessimistic Locking**: `lockForUpdate()` previne race conditions em saques simultâneos
  - **Validação em Dupla Camada**: Validação no request + validação no service
  - **Precisão Monetária**: Usando regex ao invés de float comparison (evita problemas IEEE 754)
  - Métodos específicos de validação `validateMonetaryPrecision()` e `validatePositiveAmount()`

```php
return DB::transaction(function() use ($wallet, $amount) {
    $wallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();
    if ($wallet->balance < $amount) {
        throw new Exception("Saldo insuficiente para saque.");
    }
    $wallet->balance -= $amount;
    $wallet->save();
    $wallet->transactions()->create([...]);
    return $wallet;
});
```

---

### 🔐 Justificativas de Tecnologias

#### **Laravel Sanctum** (Autenticação)
- ✅ Ideal para **SPA (Single Page Application)** com Vue.js
- ✅ Suporta **Token State** com JWT para requisições stateless
- ✅ Proteção CSRF automática integrada ao framework
- ✅ Segurança de cookies com `SameSite` e `HttpOnly`

#### **Vue 3 com Composition API**
- ✅ API moderna e reativa, reduzindo boilerplate vs Options API
- ✅ Reutilização de lógica via composables
- ✅ Melhor performance com reatividade granular
- ✅ Melhor suporte a TypeScript (opcional)

#### **Pinia** (Gerenciamento Global de Estado)
- ✅ Store pattern oficial recomendado para Vue 3
- ✅ Gerenciamento simplificado vs Vuex
- ✅ Devtools integradas para debug
- ✅ Persistência automática de estado em localStorage

#### **Tailwind CSS v4** (UI Reativa)
- ✅ Utility-first framework para desenvolvimento rápido
- ✅ Integração automática com Vite para build otimizado
- ✅ Dark mode suportado nativamente
- ✅ Componentes responsivos sem CSS customizado

#### **SQLite** (Banco de Dados)
- ✅ Zero configuração necessária
- ✅ Ideal para MVP e prototipagem rápida
- ✅ Suporte total a transações e constraints
- ✅ Deployment simplificado (arquivo único `database.sqlite`)

#### **PHPUnit + Laravel Testing** (Testes)
- ✅ Testing framework padrão Laravel com utilitários financeiros
- ✅ `RefreshDatabase` garante isolamento entre testes
- ✅ `Sanctum::actingAs()` simplifica autenticação em testes
- ✅ Assertions específicas para JSON API

---

## 🛠️ Pré-requisitos

Antes de iniciar, certifique-se de ter as seguintes ferramentas instaladas no seu sistema:

| Ferramenta | Versão Mínima | Verificação |
|-----------|----------------|-----------|
| **PHP** | 8.2+ | `php -v` |
| **Composer** | 2.0+ | `composer -V` |
| **Node.js** | 22.x+ (compatível com Vite 7.x) | `node -v` |
| **npm** | 10.x+ | `npm -v` |
| **SQLite3** | 3.8+ | `sqlite3 --version` |
| **Git** | Qualquer versão recente | `git --version` |

### Verificação Rápida

```bash
# Verifique todas as dependências de uma vez
php -v && composer -V && node -v && npm -v && sqlite3 --version
```

---

## 🚀 Instruções de Instalação e Configuração Local

### 1. Clonar o Repositório

```bash
git clone {{GITHUB_REPOSITORY_URL}}
cd wallet
```

**Substitua `{{GITHUB_REPOSITORY_URL}}` pela URL do seu repositório GitHub.**

### 2. Instalar Dependências do Backend (PHP/Composer)

```bash
composer install
```

Isso instalará:
- Laravel Framework e seus pacotes
- Laravel Sanctum (autenticação)
- PHPUnit (testes)
- Laravel Pint (code formatter)

### 3. Instalar Dependências do Frontend (Node.js/npm)

```bash
npm install
```

Isso instalará:
- Vue.js 3
- Vue Router 5
- Pinia (gerenciamento de estado)
- Tailwind CSS v4
- Vite (bundler)

### 4. Configurar Variáveis de Ambiente

```bash
# Copie o arquivo de exemplo para .env
cp .env.example .env
```

Edite o arquivo `.env` e configure as variáveis críticas:

```env
# Configuração da Aplicação
APP_NAME=Wallet
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000

# Configuração do Banco de Dados (SQLite - sem configuração adicional!)
DB_CONNECTION=sqlite
# DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD não são necessários para SQLite

# Configuração de Sessão
SESSION_DRIVER=database
SESSION_LIFETIME=120

# Cache e Queue
CACHE_STORE=database
QUEUE_CONNECTION=database

# Sanctum (Autenticação)
SANCTUM_STATEFUL_DOMAINS=localhost:3000,localhost:8000
```

### 5. Gerar Chave de Aplicação

```bash
php artisan key:generate
```

Isso irá gerar uma chave `APP_KEY` aleatória no arquivo `.env`.

### 6. Executar as Migrations (Criar Banco de Dados)

```bash
php artisan migrate
```

**Estruturas criadas:**
- `users` — Tabela de usuários
- `wallets` — Carteiras dos usuários (relacionamento 1:1)
- `transactions` — Histórico de transações (relacionamento 1:N com wallets)
- `cache`, `jobs`, `sessions` — Infraestrutura do Laravel

### 7. Executar o Seeder (Criar Usuário de Teste)

```bash
php artisan migrate:refresh --seed
```

Ou apenas o seeder:

```bash
php artisan db:seed
```

Isso criará um usuário padrão com as credenciais de teste (veja seção [Credenciais de Teste](#credenciais-de-teste) abaixo).

### 8. Iniciar o Backend (Laravel Development Server)

```bash
php artisan serve
```

A aplicação estará disponível em: **http://localhost:8000**

> Dica: Por padrão, roda na porta 8000. Para usar outra porta:
> ```bash
> php artisan serve --port=8001
> ```

### 9. Iniciar o Frontend (Vite Development Server)

Abra outro terminal e execute:

```bash
npm run dev
```

A aplicação frontend estará disponível em: **http://localhost:5173**

### 10. Executar Backend + Frontend Simultaneamente (Opcional)

Se você tem `concurrently` instalado (já incluído no `package.json`), execute:

```bash
composer run dev
```

Isso irá iniciar:
- Servidor Laravel (`php artisan serve`)
- Queue listener
- Logs (Laravel Pail)
- Vite dev server

---

## 🧪 Execução dos Testes Automatizados

A suíte de testes garante a integridade das operações financeiras críticas através de **5 cenários essenciais**:

### Executar Todos os Testes

```bash
php artisan test --filter WalletApiTest
```

### Cenários Testados

#### ✅ **1. Teste de Depósito com Sucesso** (`test_deposit_money_success`)
- **O que testa**: Depósito válido atualiza saldo e cria registro de transação
- **Validações**:
  - Resposta HTTP 200 com `message` e `balance`
  - Saldo atualizado corretamente no banco de dados
  - Transação registrada com tipo `credit` e `balance_after` correto
- **Garante**: Operações de crédito são atômicas e auditáveis

#### ✅ **2. Teste de Bloqueio de Valores Negativos** (`test_deposit_requires_amount`)
- **O que testa**: Rejeição de depósitos com valores negativos
- **Validações**:
  - Resposta HTTP 422 com erro de validação
  - Saldo permanece inalterado
  - Mensagem de erro clara em português
- **Garante**: Proteção contra operações inválidas no layer HTTP

#### ✅ **3. Teste de Saque com Sucesso** (`test_user_withdraw_success`)
- **O que testa**: Saque válido com saldo suficiente
- **Validações**:
  - Resposta HTTP 200
  - Saldo decrementado corretamente
  - Transação registrada com tipo `debit` e `balance_after` correto
- **Garante**: Operações de débito preservam consistência

#### ✅ **4. Teste de Proteção contra Saldo Insuficiente** (`test_user_withdraw_error`)
- **O que testa**: Rejeição de saques com saldo insuficiente
- **Validações**:
  - Resposta HTTP 422 com mensagem de erro
  - Saldo permanece intacto (atomicidade)
  - Nenhuma transação é registrada
- **Garante**: Proteção contra operações que violariam regras de negócio

#### ✅ **5. Teste de Proteção contra Frações de Centavo** (`test_withdraw_fractioned_amounts_error`)
- **O que testa**: Rejeição de valores com mais de 2 casas decimais (ex: `10.005`)
- **Validações**:
  - Resposta HTTP 422 com erro de validação no campo `amount`
  - Saldo não é alterado (operação bloqueada no request layer)
  - Validação ocorre ANTES de atingir a lógica de negócio
- **Garante**: Precisão monetária e prevenção de erros de arredondamento

### Executar com Cobertura de Código

```bash
php artisan test --filter WalletApiTest --coverage
```

### Executar Teste Específico

```bash
php artisan test --filter test_deposit_money_success
```

### Output Esperado

```
   PASS  Tests/Feature/WalletApiTest.php
  ✓ test deposit money success
  ✓ test deposit requires amount
  ✓ test user withdraw success
  ✓ test user withdraw error
  ✓ test withdraw fractioned amounts error

5 passed (45ms)
```

---

## 🌐 Deploy Público e Credenciais de Teste

### 📍 Repositório no GitHub

```
🔗 {{GITHUB_REPOSITORY_URL}}
```

**Substitua a URL acima pelo link de seu repositório GitHub.**

### 🚀 Deploy Público da Aplicação

```
🔗 {{DEPLOYED_APPLICATION_URL}}
```

**Substitua a URL acima pelo link de acesso público (ex: Vercel, Railway, Heroku, etc).**

---

### 🔑 Credenciais de Teste

Use as credenciais abaixo para fazer login na aplicação:

| Campo | Valor |
|-------|-------|
| **Email** | `test@akrk.com.br` |
| **Senha** | `password` |
| **Saldo Inicial** | `R$ 0,00` |

#### Passos para Testar:

1. Abra a aplicação no navegador
2. Clique em "Login" ou acesse `/login`
3. Digite as credenciais acima
4. Após autenticação, você será redirecionado para o dashboard
5. Teste as funcionalidades:
   - 💰 **Fazer um depósito**: Clique em "Novo Depósito" e informe um valor válido (ex: `100.00`)
   - 💸 **Fazer um saque**: Clique em "Saque" após ter saldo disponível
   - 📊 **Visualizar métricas**: Dashboard mostra total depositado/sacado no mês
   - 📝 **Ver histórico**: Seção de transações lista todas as operações

---

## 📚 Estrutura do Projeto

```
wallet/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── WalletController.php       # Controller fino para roteamento HTTP
│   │   └── Requests/
│   │       ├── DepositRequest.php         # Validação de depósitos
│   │       └── WithdrawRequest.php        # Validação de saques
│   ├── Models/
│   │   ├── User.php
│   │   ├── Wallet.php
│   │   └── Transaction.php
│   ├── Services/
│   │   └── WalletService.php              # Service Pattern com lógica de negócio
│   └── Providers/
│       └── AppServiceProvider.php
├── database/
│   ├── migrations/                        # Estrutura do banco SQLite
│   └── seeders/
│       └── DatabaseSeeder.php             # Criação de usuário de teste
├── resources/
│   ├── css/
│   │   └── app.css                        # Tailwind CSS
│   ├── js/
│   │   ├── bootstrap.js                   # Inicialização do Axios
│   │   ├── App.vue                        # Componente raiz
│   │   ├── stores/
│   │   │   └── walletStore.js             # Pinia store (estado global)
│   │   ├── router/
│   │   │   └── index.js                   # Rotas Vue
│   │   ├── services/
│   │   │   └── api.js                     # Cliente HTTP (Axios)
│   │   └── views/                         # Componentes de página
│   └── views/
│       └── app.blade.php                  # Template HTML base
├── routes/
│   ├── api.php                            # Rotas de API (autenticadas)
│   └── web.php                            # Rotas web (SPA)
├── tests/
│   └── Feature/
│       └── WalletApiTest.php              # Testes das operações de carteira
├── composer.json                          # Dependências PHP
├── package.json                           # Dependências Node.js
├── vite.config.js                         # Configuração Vite
├── phpunit.xml                            # Configuração PHPUnit
└── README.md                              # Este arquivo
```

---

## 🔒 Segurança e Boas Práticas Implementadas

- ✅ **Autenticação Stateless**: Laravel Sanctum com tokens JWT
- ✅ **Proteção CSRF**: Middleware automático do Laravel
- ✅ **Hash de Senhas**: Bcrypt com 12 rounds
- ✅ **Validação em Dupla Camada**: Request + Service
- ✅ **Transações Atômicas**: `DB::transaction()` garante ACID
- ✅ **Pessimistic Locking**: `lockForUpdate()` previne race conditions
- ✅ **Precisão Monetária**: Regex para máximo 2 casas decimais
- ✅ **Testes Automatizados**: 5 cenários críticos cobertos por PHPUnit
- ✅ **Variáveis de Ambiente**: Dados sensíveis nunca no código

---

## 📖 Documentação Adicional

- [Laravel Sanctum](https://laravel.com/docs/12.x/sanctum)
- [Vue 3 Composition API](https://vuejs.org/guide/extras/composition-api-faq.html)
- [Pinia Store](https://pinia.vuejs.org/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Vite](https://vitejs.dev/)

---

## 📄 Licença

Este projeto está licenciado sob a licença MIT — veja o arquivo [LICENSE](./LICENSE) para detalhes.

---

**Desenvolvido com ❤️ para avaliação técnica — Teck Soluções**

*Versão 1.0 — Maio de 2026*

---

## 🐳 Docker & Deploy no Railway

Se você escolheu usar Docker (recomendado para ambientes reproduzíveis), este projeto já inclui um `Dockerfile` pronto. Abaixo está o procedimento mínimo para configurar o Railway e comandos úteis para testes locais.

### Dockerfile Path (Railway)

No painel do Railway, em _Settings_ do service, aponte o campo **Dockerfile Path** para:

```
Dockerfile
```

### Build & Start (Railway)

- Build: o Railway irá construir a imagem usando o `Dockerfile` do repositório.
- Start: deixe o `Start Command` em branco e use o `Procfile` (`web: bash start.sh`) ou defina `Start Command` como:

```
bash start.sh
```

### Variáveis de Ambiente ESSENCIAIS (Railway)

Configure estas variáveis no painel do Railway (Environment Variables):

- `APP_ENV=production`
- `APP_DEBUG=false`
- `DB_CONNECTION=sqlite`
- `DB_DATABASE=/app/database/database.sqlite`
- `CACHE_STORE=file`
- `SESSION_DRIVER=file`
- `QUEUE_CONNECTION=sync`
- `PORT=8080` (opcional — Railway injeta uma porta automaticamente)

Também mantenha as outras variáveis sensíveis (APP_KEY, MAIL_*, etc.).

### Volume (Railway)

Monte o volume `wallet-volume` no path `/app/database` para persistir o arquivo SQLite. Isso garante que o banco sobreviva a reinícios.

### Comandos Docker locais (teste rápido)

```bash
# Build
docker build -t wallet-app .

# Roda com volume montado para persistência
docker run --rm -p 8080:8080 -v $(pwd)/database:/app/database --env-file .env -e DB_DATABASE=/app/database/database.sqlite wallet-app
```

Após o container iniciar, acesse `http://localhost:8080`.

### Observações práticas
- O `deploy.sh` já garante criação do arquivo SQLite no caminho apontado por `DB_DATABASE` e aplica migrations+seed automaticamente se o DB estiver vazio.
- `start.sh` lida com fallback (Apache helper ou `php -S`) e o `Procfile` invoca `bash start.sh`.
- Certifique-se que `start.sh` esteja com permissão executável (`chmod +x start.sh`) — o `Dockerfile` já faz isso.

Se quiser que eu gere uma versão `Dockerfile` multi-stage mais enxuta (imagem final menor), eu posso criar em seguida.
