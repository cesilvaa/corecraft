#!/bin/bash
set -e

BITCOIN_DEST="/opt/bitcoin"

if [ ! -f "$BITCOIN_DEST/bin/bitcoind" ]; then
    echo "[bitcoin-regtest] Buscando versão mais recente do Bitcoin Core..."
    LATEST=$(curl -sf https://api.github.com/repos/bitcoin/bitcoin/releases/latest \
        | jq -r '.tag_name' | sed 's/^v//')
    echo "[bitcoin-regtest] Baixando Bitcoin Core ${LATEST}..."
    mkdir -p "$BITCOIN_DEST"
    curl -fSL "https://bitcoincore.org/bin/bitcoin-core-${LATEST}/bitcoin-${LATEST}-x86_64-linux-gnu.tar.gz" \
        | tar -xz -C "$BITCOIN_DEST" --strip-components=1
    echo "[bitcoin-regtest] Bitcoin Core ${LATEST} instalado."
fi

DATADIR="/workspace/bitcoin"
PIDFILE="${DATADIR}/bitcoind.pid"

mkdir -p "$DATADIR"
envsubst '${BITCOIN_RPC_USER} ${BITCOIN_RPC_PASSWORD}' \
    < /etc/bitcoin/bitcoin.conf.template \
    > "${DATADIR}/bitcoin.conf"
echo "[bitcoin-regtest] Configuração gerada."

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "[bitcoin-regtest] bitcoind já está em execução (pid $(cat "$PIDFILE"))"
else
    rm -f "$PIDFILE"
    bitcoind -datadir="$DATADIR" -daemon -pid="$PIDFILE"
    echo "[bitcoin-regtest] bitcoind iniciado na rede regtest."
fi

exec "$@"
