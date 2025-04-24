FROM fedora:latest

# Install Bitcoin Core using DNF
RUN dnf -y install \
    bitcoind \
    bitcoin-cli \
    python3 \
    git \
    && dnf clean all

# Clone Bitcoin Core repository for signet tools
RUN git clone https://github.com/bitcoin/bitcoin.git /tmp/bitcoin && \
    cd /tmp/bitcoin/contrib/signet && \
    python3 generate_challenge.py > /home/bitcoin/challenge.txt && \
    python3 generate_keys.py > /home/bitcoin/keys.txt

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

# Create startup script
RUN echo '#!/bin/bash\n\
    if [ ! -f /home/bitcoin/.bitcoin/signet_address.txt ]; then\n\
    bitcoin-cli -signet -rpcuser=bitcoin -rpcpassword=bitcoin getnewaddress > /home/bitcoin/.bitcoin/signet_address.txt\n\
    fi\n\
    MINER_ADDRESS=$(cat /home/bitcoin/.bitcoin/signet_address.txt)\n\
    CHALLENGE=$(cat /home/bitcoin/challenge.txt)\n\
    \n\
    exec bitcoind \
    -signet \
    -printtoconsole \
    -datadir=/home/bitcoin/.bitcoin \
    -bind=0.0.0.0 \
    -port=38333 \
    -rpcport=38332 \
    -rpcuser=bitcoin \
    -rpcpassword=bitcoin \
    -rpcbind=0.0.0.0 \
    -rpcallowip=0.0.0.0/0 \
    -server=1 \
    -prune=1000 \
    -dbcache=512 \
    -maxconnections=16 \
    -gen=1 \
    -signetchallenge=${CHALLENGE} \
    -mineraddress=${MINER_ADDRESS}' > /home/bitcoin/startup.sh && \
    chmod +x /home/bitcoin/startup.sh

CMD ["/home/bitcoin/startup.sh"]
