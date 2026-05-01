# CoreCraft

Repositorio de estudos e atividades do programa CoreCraft, da BitcoinCoders.

O objetivo deste repositório é organizar os trabalhos desenvolvidos ao longo do curso, com foco em entender o Bitcoin Core em nível de arquitetura e operá-lo de ponta a ponta: linha de comando, integração via RPC e ZMQ, interpretação da mempool, acompanhamento de transações e reação a eventos da rede em tempo real.

## Estrutura

```text
corecraft/
├── atividade-1/   Rails API — integração com Bitcoin Core via RPC
├── atividade-2/
├── atividade-3/
├── docker-compose.yml
└── README.md
```

## Atividades

### atividade-1

Rails 8 API que se conecta a nodes Bitcoin Core via JSON-RPC.

**Ambientes**

| Ambiente | Rede | Node | Porta RPC |
|----------|------|------|-----------|
| `development` | regtest | node1 | 18443 |
| `sandbox` | signet | node2 | 18463 |

**Como rodar**

```bash
# Copiar os templates
cp atividade-1/.env.example atividade-1/.env.development
cp atividade-1/.env.sandbox.example atividade-1/.env.sandbox
```

Abra cada arquivo e preencha as variáveis com os dados do node ao qual você tem acesso:

- `BITCOIN_RPC_HOST` — hostname ou IP do node
- `BITCOIN_RPC_PORT` — porta RPC do node
- `BITCOIN_RPC_USER` — usuário definido em `rpcuser` no `bitcoin.conf`
- `BITCOIN_RPC_PASSWORD` — senha definida em `rpcpassword` no `bitcoin.conf`

```bash
# development (padrão)
docker compose up

# sandbox
RAILS_ENV=sandbox docker compose up
```

**Trocando de ambiente**

Se você já está rodando em `development` e quer subir em `sandbox`:

```bash
# 1. Parar e remover o container atual
docker stop corecraft-v1 && docker rm corecraft-v1

# 2. Subir com o ambiente sandbox
RAILS_ENV=sandbox docker compose up
```

Para voltar ao development:

```bash
docker stop corecraft-v1 && docker rm corecraft-v1
docker compose up
```

**Endpoints disponíveis**

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/` | Status da aplicação |
| `GET` | `/up` | Health check |
| `GET` | `/api/mempool/summary` | Resumo da mempool via RPC |

## Requisitos

- Docker e Docker Compose
- Container Bitcoin Core rodando e acessível na rede Docker `ubuntu_default`
