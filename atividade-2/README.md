# corecraft-v2

Rails API that connects to Bitcoin Core nodes via JSON-RPC and ZMQ.

## Requirements

- Docker and Docker Compose
- A running Bitcoin Core container accessible on the `ubuntu_default` Docker network

## Environments

| Environment | Network | Node | RPC Port | ZMQ Port |
|-------------|---------|------|----------|----------|
| `development` | regtest | node1 | 18443 | 28332 |
| `sandbox` | signet | node2 | 18473 | 28335 |

## Setup

1. Copy the env file for your target environment:

   ```bash
   # development
   cp .env.example .env.development

   # sandbox
   cp .env.sandbox.example .env.sandbox
   ```

2. Fill in `BITCOIN_RPC_PASSWORD` with the actual RPC credentials.

3. Set `BITCOIN_ZMQ_ENABLED=true` to enable the ZMQ listener.

## Running

```bash
# development (default)
docker compose up corecraft-v2

# sandbox
RAILS_ENV=sandbox docker compose up corecraft-v2
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | App status |
| `GET` | `/up` | Health check |
| `GET` | `/api/mempool/summary` | Mempool summary via Bitcoin RPC |
| `GET` | `/api/blockchain/lag` | Node sync lag via Bitcoin RPC |
| `GET` | `/api/events/summary` | ZMQ event counters and tx rate |
| `GET` | `/api/events/latest` | Latest blocks and txs observed via ZMQ |
| `GET` | `/api/events/state-comparison` | Divergence between ZMQ and RPC best block |
| `GET` | `/panel` | Web dashboard |

## Running tests

```bash
docker exec corecraft-v2 bundle exec rspec --format documentation
```

## Populating the panel (regtest)

These commands are meant to be run **inside the Bitcoin Core container**:

```bash
docker exec -it ubuntu bash
```

Once inside, set the node path:

```bash
export BITCOIN_CLI=/opt/bitcoin/bin/bitcoin-cli
export NODE_DATADIR=/workspace/bitcoin/node1
```

### 1. Create wallet and get a mining address

```bash
$BITCOIN_CLI -datadir=$NODE_DATADIR createwallet "main"

ADDR=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
echo "Mining address: $ADDR"
```

### 2. Mine initial blocks (required to have spendable balance)

```bash
$BITCOIN_CLI -datadir=$NODE_DATADIR generatetoaddress 101 $ADDR
```

### 3. Send transactions with varied fee rates (populates Mempool Intelligence)

```bash
# High fee (> 50 sat/vB)
for RATE in 100 75 60; do
  DEST=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
  $BITCOIN_CLI -named -datadir=$NODE_DATADIR sendtoaddress address=$DEST amount=0.005 fee_rate=$RATE
done

# Medium fee (10–50 sat/vB)
for RATE in 30 20 12; do
  DEST=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
  $BITCOIN_CLI -named -datadir=$NODE_DATADIR sendtoaddress address=$DEST amount=0.005 fee_rate=$RATE
done

# Low fee (< 10 sat/vB)
for RATE in 5 3 2; do
  DEST=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
  $BITCOIN_CLI -named -datadir=$NODE_DATADIR sendtoaddress address=$DEST amount=0.005 fee_rate=$RATE
done
```

### 4. Mine a few more blocks (confirms transactions, triggers ZMQ block events)

```bash
$BITCOIN_CLI -datadir=$NODE_DATADIR generatetoaddress 5 $ADDR
```

### 5. Send more transactions to repopulate the mempool

```bash
for RATE in 100 75 60 30 20 12 5 3 2; do
  DEST=$($BITCOIN_CLI -datadir=$NODE_DATADIR getnewaddress)
  $BITCOIN_CLI -named -datadir=$NODE_DATADIR sendtoaddress address=$DEST amount=0.005 fee_rate=$RATE
done
```

After these steps, the dashboard at `http://localhost:3000/panel` should show:

- **Mempool Intelligence** — 9 transactions with low/medium/high fee distribution
- **Node Sync Status** — blocks downloaded, fully synced
- **Event Activity** — blocks and transactions captured via ZMQ
- **Latest Events** — recent block hashes and txids
- **Divergence banner** — green (ZMQ and RPC in sync)

## Ruby and Rails versions

- Ruby 4.0.3
- Rails 8.1.3
