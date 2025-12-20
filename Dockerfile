# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

LABEL title="rAthena - Dockerized server" \
  maintainer="Carlos Milán Figueredo" \
  version="1.1" \
  url1="https://calnus.com" \
  url2="http://www.hispamsx.org" \
  bbs="telnet://bbs.hispamsx.org" \
  twitter="@cmilanf" \
  thanksto1="Beatriz Sebastián Peña" \
  thanksto2="Alberto Marcos González"

# Environment variables are documented in docker-entrypoint.sh and README.md
# Key variables: MYSQL_HOST, MYSQL_DATABASE, MYSQL_USERNAME, MYSQL_PASSWORD,
# SERVER_MODE, RENEWAL, SET_SERVER_NAME, and many more configuration options

# Build arguments
ARG PACKETVER=20200401
ARG PACKET_OBFUSCATION=0
ARG SERVER_MODE=classic
ARG RENEWAL=false
ARG RATHENA_COMMIT=master

# Environment variables (defaults from build args)
ENV PACKETVER=${PACKETVER}
ENV PACKET_OBFUSCATION=${PACKET_OBFUSCATION}
ENV SERVER_MODE=${SERVER_MODE}
ENV RENEWAL=${RENEWAL}
ENV RATHENA_COMMIT=${RATHENA_COMMIT}

# Update package lists and install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    make \
    gcc \
    g++ \
    libmariadb-dev \
    libmariadb-dev-compat \
    zlib1g-dev \
    libpcre3-dev \
    nano \
    dos2unix \
    default-mysql-client \
    bind9-dnsutils \
    linux-headers-generic \
    && rm -rf /var/lib/apt/lists/*

# Clone the rAthena repository at specific commit
RUN git clone https://github.com/rathena/rathena.git /opt/rAthena

WORKDIR /opt/rAthena
RUN git checkout ${RATHENA_COMMIT}

# Copy essential SQL files from the cloned repository (YAML mode - minimal SQL required)
RUN mkdir -p /opt/sql && \
    # Copy only essential SQL files needed for YAML mode
    cp /opt/rAthena/sql-files/main.sql /opt/sql/ 2>/dev/null || true && \
    cp /opt/rAthena/sql-files/logs.sql /opt/sql/ 2>/dev/null || true && \
    cp /opt/rAthena/sql-files/roulette_default_data.sql /opt/sql/ 2>/dev/null || true && \
    # Copy item_cash_db files if they exist (optional for cash shop)
    cp /opt/rAthena/sql-files/item_cash_db.sql /opt/sql/ 2>/dev/null || true && \
    cp /opt/rAthena/sql-files/item_cash_db2.sql /opt/sql/ 2>/dev/null || true

# Build the rAthena server
WORKDIR /opt/rAthena

RUN if [ ${PACKET_OBFUSCATION} -ne 1 ]; then \
        sed -i '/#ifndef PACKET_OBFUSCATION/,/#endif/s/^/\/\//' /opt/rAthena/src/config/packets.hpp; \
    fi

# Configure and build rAthena based on SERVER_MODE
RUN if [ "${SERVER_MODE}" = "classic" ]; then \
        echo "Building for Classic/Pre-Renewal mode"; \
        ./configure --enable-packetver=${PACKETVER} --enable-prere=yes; \
    else \
        echo "Building for Renewal mode"; \
        ./configure --enable-packetver=${PACKETVER}; \
    fi && \
    make clean && \
    make server && \
    chmod a+x login-server char-server map-server web-server

# Copy additional files
COPY docker-entrypoint.sh /usr/local/bin/
COPY accountsandchars.sql /root/
COPY gab_npc.txt /opt/rAthena/npc/custom/

# Expose ports
EXPOSE 6900/tcp 6121/tcp 5121/tcp

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/opt/rAthena/athena-start", "watch"]
