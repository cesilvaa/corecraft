# CoreCraft

Repositório de estudos e atividades do programa CoreCraft, da BitcoinCoders.

O objetivo deste repositório é organizar os trabalhos desenvolvidos ao longo do curso, com foco em entender o Bitcoin Core em nível de arquitetura e operá-lo de ponta a ponta: linha de comando, integração via RPC e ZMQ, interpretação da mempool, acompanhamento de transações e reação a eventos da rede em tempo real.

## Estrutura

```text
corecraft/
├── atividade-1/   corecraft-v1
├── atividade-2/   corecraft-v2
├── atividade-3/   corecraft-v3
├── docker-compose.yml
└── README.md
```

## Versões

### corecraft-v1 — atividade-1

Rails API que se conecta a nodes Bitcoin Core via JSON-RPC. Expõe dados da mempool e status de sincronização, além de um dashboard web com dois cards:

- **Mempool Intelligence** — distribuição de transações por faixa de fee
- **Node Sync Status** — progresso de download de blocos e lag

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/` | Status da aplicação |
| `GET` | `/up` | Health check |
| `GET` | `/api/mempool/summary` | Resumo da mempool via RPC |
| `GET` | `/api/blockchain/lag` | Lag de sincronização do node |
| `GET` | `/panel` | Dashboard web |

---

### corecraft-v2 — atividade-2

Evolução da v1 com integração ZMQ. Além de tudo da v1, subscreve eventos `hashblock` e `hashtx` publicados pelo Bitcoin Core em tempo real e os armazena em memória.

Novos cards no dashboard:

- **Event Activity** — contadores de blocos e transações capturados via ZMQ, taxa tx/s
- **Latest Events** — hashes dos últimos blocos e txids recentes
- **Divergence banner** — indica divergência entre o melhor bloco segundo ZMQ e segundo RPC

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/events/summary` | Contadores ZMQ e taxa de transações |
| `GET` | `/api/events/latest` | Últimos blocos e txs observados via ZMQ |
| `GET` | `/api/events/state-comparison` | Divergência entre ZMQ e RPC best block |

---

### corecraft-v3 — atividade-3

Em desenvolvimento.

---

## Requisitos

- Docker e Docker Compose
- Container Bitcoin Core rodando e acessível em uma rede Docker externa

---

## Configuração

### Rede Docker

O `docker-compose.yml` precisa saber em qual rede Docker o container Bitcoin Core está disponível. Copie os arquivos de exemplo na raiz e preencha com o nome da sua rede:

```bash
cp .env.example .env
cp .env.sandbox.example .env.sandbox
```

| Variável | Descrição |
|----------|-----------|
| `BITCOIN_DOCKER_NETWORK` | Nome da rede Docker externa onde o Bitcoin Core está acessível (veja `docker network ls`) |

> O Docker Compose carrega `.env` automaticamente. Para o ambiente sandbox, o arquivo `.env.sandbox` precisa ser passado explicitamente via `--env-file` (veja os comandos em [Como executar](#como-executar)).

### Variáveis da aplicação

Cada versão tem seus próprios arquivos de ambiente dentro de `atividade-N/`. Os arquivos `.env.development` e `.env.sandbox` **não são versionados** — crie-os a partir dos templates:

```bash
# development
cp atividade-N/.env.example atividade-N/.env.development

# sandbox
cp atividade-N/.env.sandbox.example atividade-N/.env.sandbox
```

### Variáveis de ambiente

**Ambiente `development`** conecta a um node **regtest**.  
**Ambiente `sandbox`** conecta a um node **signet**.

Preencha com os dados do node ao qual você tem acesso:

| Variável | Descrição |
|----------|-----------|
| `BITCOIN_RPC_HOST` | Hostname ou IP do node Bitcoin Core |
| `BITCOIN_RPC_PORT` | Porta RPC configurada no `bitcoin.conf` |
| `BITCOIN_RPC_USER` | Usuário definido em `rpcuser` |
| `BITCOIN_RPC_PASSWORD` | Senha definida em `rpcpassword` |
| `BITCOIN_RPC_NETWORK` | `regtest` (development) ou `signet` (sandbox) |

A partir da **v2**, há variáveis adicionais para o listener ZMQ:

| Variável | Descrição |
|----------|-----------|
| `BITCOIN_ZMQ_HOST` | Hostname ou IP do node (geralmente o mesmo do RPC) |
| `BITCOIN_ZMQ_PORT` | Porta ZMQ configurada em `zmqpubhashblock` / `zmqpubhashtx` no `bitcoin.conf` |
| `BITCOIN_ZMQ_ENABLED` | `true` para ativar o listener |

### Convenção de arquivos de ambiente

| Arquivo | Versionado | Finalidade |
|---------|------------|-----------|
| `.env.example` | Sim | Template para development |
| `.env.sandbox.example` | Sim | Template para sandbox |
| `.env.development` | **Não** | Credenciais reais de development |
| `.env.sandbox` | **Não** | Credenciais reais de sandbox |

---

## Como executar

```bash
# corecraft-v1 — development (padrão)
docker compose up corecraft-v1

# corecraft-v1 — sandbox
RAILS_ENV=sandbox docker compose --env-file .env.sandbox up corecraft-v1

# corecraft-v2 — development (padrão)
docker compose up corecraft-v2

# corecraft-v2 — sandbox
RAILS_ENV=sandbox docker compose --env-file .env.sandbox up corecraft-v2
```

### Trocando de ambiente

```bash
# Parar e remover o container atual
docker stop corecraft-vN && docker rm corecraft-vN

# Subir com o outro ambiente
RAILS_ENV=sandbox docker compose --env-file .env.sandbox up corecraft-vN
```

---

## Executando os testes

```bash
# corecraft-v1
docker exec corecraft-v1 bundle exec rspec --format documentation

# corecraft-v2
docker exec corecraft-v2 bundle exec rspec --format documentation
```

---

## Populando o panel (regtest)

Os comandos abaixo devem ser executados **dentro do container Bitcoin Core**:

```bash
docker exec -it ubuntu bash
```

Dentro do container, defina o caminho do `bitcoin-cli` e do datadir do node regtest que você quer usar:

```bash
export BITCOIN_CLI=/opt/bitcoin/bin/bitcoin-cli
export NODE_DATADIR=<caminho-do-datadir-do-node-regtest>
```

### 1. Criar (ou carregar) a wallet e obter um endereço de mineração

```bash
$BITCOIN_CLI -datadir=$NODE_DATADIR createwallet "main" 2>/dev/null || \
  $BITCOIN_CLI -datadir=$NODE_DATADIR loadwallet "main" 2>/dev/null || \
  echo "Wallet already loaded"

ADDR=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
echo "Mining address: $ADDR"
```

### 2. Minerar os blocos iniciais (necessário para ter saldo disponível)

```bash
$BITCOIN_CLI -datadir=$NODE_DATADIR generatetoaddress 101 $ADDR
```

### 3. Enviar transações com fee rates variados (popula o Mempool Intelligence)

```bash
# Fee alta (> 50 sat/vB)
for RATE in 100 75 60; do
  DEST=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
  $BITCOIN_CLI -named -datadir=$NODE_DATADIR sendtoaddress address=$DEST amount=0.005 fee_rate=$RATE
done

# Fee média (10–50 sat/vB)
for RATE in 30 20 12; do
  DEST=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
  $BITCOIN_CLI -named -datadir=$NODE_DATADIR sendtoaddress address=$DEST amount=0.005 fee_rate=$RATE
done

# Fee baixa (< 10 sat/vB)
for RATE in 5 3 2; do
  DEST=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
  $BITCOIN_CLI -named -datadir=$NODE_DATADIR sendtoaddress address=$DEST amount=0.005 fee_rate=$RATE
done
```

### 4. Minerar mais alguns blocos (confirma transações e dispara eventos ZMQ)

> Os cards **Event Activity**, **Latest Events** e o **Divergence banner** só estão disponíveis na **v2 em diante**.

```bash
$BITCOIN_CLI -datadir=$NODE_DATADIR generatetoaddress 5 $ADDR
```

### 5. Enviar mais transações para repopular a mempool

```bash
for RATE in 100 75 60 30 20 12 5 3 2; do
  DEST=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
  $BITCOIN_CLI -named -datadir=$NODE_DATADIR sendtoaddress address=$DEST amount=0.005 fee_rate=$RATE
done
```

Após esses passos, o dashboard em `http://localhost:3000/panel` deve exibir:

- **Mempool Intelligence** — 9 transações com distribuição low/medium/high *(v1 em diante)*
- **Node Sync Status** — blocos baixados, totalmente sincronizado *(v1 em diante)*
- **Event Activity** — blocos e transações capturados via ZMQ *(v2 em diante)*
- **Latest Events** — hashes recentes de blocos e txids *(v2 em diante)*
- **Divergence banner** — verde (ZMQ e RPC em sincronia) *(v2 em diante)*
