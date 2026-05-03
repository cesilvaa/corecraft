#!/bin/bash
set -e

BITCOIN_DEST="/opt/bitcoin"

if [ ! -d "$BITCOIN_DEST" ]; then
    echo "[bitcoin] Buscando versão mais recente do Bitcoin Core..."
    LATEST=$(curl -sf https://api.github.com/repos/bitcoin/bitcoin/releases/latest \
        | jq -r '.tag_name' | sed 's/^v//')
    echo "[bitcoin] Baixando Bitcoin Core ${LATEST}..."
    mkdir -p "$BITCOIN_DEST"
    curl -fSL "https://bitcoincore.org/bin/bitcoin-core-${LATEST}/bitcoin-${LATEST}-x86_64-linux-gnu.tar.gz" \
        | tar -xz -C "$BITCOIN_DEST" --strip-components=1
    echo "[bitcoin] Bitcoin Core ${LATEST} instalado."
fi

# Gerar bitcoin.conf a partir dos templates (executado a cada inicialização
# para refletir mudanças nas variáveis de ambiente)
for NODE in node1 node2; do
    mkdir -p "/workspace/bitcoin/${NODE}"
    envsubst '${BITCOIN_RPC_USER} ${BITCOIN_RPC_PASSWORD}' \
        < "/etc/bitcoin/${NODE}/bitcoin.conf.template" \
        > "/workspace/bitcoin/${NODE}/bitcoin.conf"
    echo "[bitcoin] Config de ${NODE} gerada."
done

start_node() {
    local datadir="$1"
    local name
    name=$(basename "$datadir")
    local pidfile="${datadir}/bitcoind.pid"

    if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        echo "[bitcoin] ${name} já está em execução (pid $(cat "$pidfile"))"
    else
        rm -f "$pidfile"
        bitcoind -datadir="$datadir" -daemon -pid="$pidfile"
        echo "[bitcoin] ${name} iniciado."
    fi
}

start_node /workspace/bitcoin/node1
start_node /workspace/bitcoin/node2

exec "$@"
