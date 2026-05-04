FROM ubuntu:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl jq gettext-base \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/bitcoin/bin:$PATH"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY bitcoin.conf.template /etc/bitcoin/bitcoin.conf.template

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["sleep", "infinity"]
