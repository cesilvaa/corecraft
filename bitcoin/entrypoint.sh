#!/bin/bash
set -e

BITCOIN_DEST="/opt/bitcoin"

if [ ! -f "$BITCOIN_DEST/bin/bitcoind" ]; then
    echo "[bitcoin] Buscando versão mais recente do Bitcoin Core..."
    LATEST=$(curl -sf https://api.github.com/repos/bitcoin/bitcoin/releases/latest \
        | jq -r '.tag_name' | sed 's/^v//')
    echo "[bitcoin] Baixando Bitcoin Core ${LATEST}..."
    mkdir -p "$BITCOIN_DEST"
    curl -fSL "https://bitcoincore.org/bin/bitcoin-core-${LATEST}/bitcoin-${LATEST}-x86_64-linux-gnu.tar.gz" \
        | tar -xz -C "$BITCOIN_DEST" --strip-components=1
    echo "[bitcoin] Bitcoin Core ${LATEST} instalado."
fi

start_node() {
    local node="$1"
    local network="$2"
    local datadir="/workspace/bitcoin/${node}"
    local pidfile="${datadir}/bitcoind.pid"

    mkdir -p "$datadir"
    NODE_ACTIVE_NETWORK="$network" \
        envsubst '${BITCOIN_RPC_USER} ${BITCOIN_RPC_PASSWORD} ${NODE_ACTIVE_NETWORK}' \
        < "/etc/bitcoin/${node}/bitcoin.conf.template" \
        > "${datadir}/bitcoin.conf"
    echo "[bitcoin] Config de ${node} (${network}) gerada."

    if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        echo "[bitcoin] ${node} já está em execução (pid $(cat "$pidfile"))"
    else
        rm -f "$pidfile"
        bitcoind -datadir="$datadir" -daemon -pid="$pidfile"
        echo "[bitcoin] ${node} iniciado na rede ${network}."
    fi
}

if [ -n "$NODE1_NETWORK" ]; then
    start_node node1 "$NODE1_NETWORK"
fi

if [ -n "$NODE2_NETWORK" ]; then
    start_node node2 "$NODE2_NETWORK"
fi

exec "$@"
