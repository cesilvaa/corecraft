# corecraft-v1

Rails API that connects to Bitcoin Core nodes via JSON-RPC.

## Requirements

- Docker and Docker Compose
- A running Bitcoin Core container accessible on the `ubuntu_default` Docker network

## Environments

| Environment | Network | Node | RPC Port |
|-------------|---------|------|----------|
| `development` | regtest | node1 | 18443 |
| `sandbox` | signet | node2 | 18463 |

## Setup

1. Copy the env file for your target environment:

   ```bash
   # development
   cp .env.example .env.development

   # sandbox
   cp .env.sandbox.example .env.sandbox
   ```

2. Fill in `BITCOIN_RPC_PASSWORD` with the actual RPC credentials.

## Running

```bash
# development (default)
docker compose up

# sandbox
RAILS_ENV=sandbox docker compose up
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | App status |
| `GET` | `/up` | Health check |
| `GET` | `/api/mempool/summary` | Mempool summary via Bitcoin RPC |

## Running tests

```bash
docker exec corecraft-v1 bundle exec rspec
```

## Ruby and Rails versions

- Ruby 4.0.3
- Rails 8.1.3
