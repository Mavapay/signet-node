FROM fedora:latest

# Install Bitcoin Core using DNF
RUN dnf -y install \
    bitcoind \
    bitcoin-cli \
    && dnf clean all

# Setup environment variables
ENV BITCOIN_DATA=/home/bitcoin/.bitcoin

# Create bitcoin data directory
RUN mkdir -p ${BITCOIN_DATA}

# Set permissions
RUN chown -R bitcoin:bitcoin ${BITCOIN_DATA} && \
    chmod -R 755 ${BITCOIN_DATA}

# Expose ports (38333 for P2P, 38332 for RPC)
EXPOSE 38333 38332

# Switch to bitcoin user
USER bitcoin

# Run bitcoind with all configurations
CMD ["bitcoind", \
    "-signet", \
    "-printtoconsole", \
    "-datadir=/home/bitcoin/.bitcoin", \
    "-bind=0.0.0.0", \
    "-port=38333", \
    "-rpcport=38332", \
    "-rpcuser=bitcoin", \
    "-rpcpassword=bitcoin", \
    "-rpcbind=0.0.0.0", \
    "-rpcallowip=0.0.0.0/0", \
    "-server=1", \
    "-prune=1000", \
    "-dbcache=512", \
    "-maxconnections=16" \
    ]
