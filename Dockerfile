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

LABEL DOWNLOAD_OVERRIDE_CONF_URL="If defined, it will download a ZIP file with the import configuration overrides. If this is the case, no environment variables applies." \
  SERVER_MODE="Compile-time server mode: 'classic' or 'renewal'. Controls compiled formulas (ASPD, HP, etc). Default: classic." \
  RENEWAL="Runtime renewal mode: true/false. Controls server_type config and YAML directories loaded. Default: false (Pre-Renewal)." \
  MYSQL_HOST="Hostname of the MySQL database. Ex: calnus-beta.mysql.database.azure.com." \
  MYSQL_DATABASE="Name of the MySQL database." \
  MYSQL_USERNAME="Database username for authentication." \
  MYSQL_PASSWORD="Password for authenticating with database. WARNING: it will be visible from Azure Portal." \
  MYSQL_ACCOUNTSANDCHARS="To whatever to execute the accountsandchars.sql so GM and bot accounts get precreated in the database" \
  SET_CHAR_TO_LOGIN_IP="IP that CHAR server uses to connect to LOGIN." \
  SET_MAP_TO_CHAR_IP="IP that MAP server uses to connect to CHAR." \
  SET_CHAR_PUBLIC_IP="Public IP of CHAR server." \
  SET_MAP_PUBLIC_IP="Public IP of MAP server." \
  ADD_SUBNET_MAP1="Subnet mapping in format: net-submask:char_ip:map_ip. Check is check is if((net-submask & char_ip ) == (net-submask & servip)) => ok" \
  SET_INTERSRV_USERID="UserID for interserver communication." \
  SET_INTERSRV_PASSWD="Password for interserver communication." \
  SET_SERVER_NAME="DisplayName of the rAthena server" \
  SET_MAX_CONNECT_USER="Maximun number of users allowed to connect concurrently. Default is unlimited." \
  SET_START_ZENNY="Amount of zenny to start with. Default is 0." \
  SET_START_POINT="Point where newly created characters will start AFTER trainning. Format: <map_name>,<x>,<y>{:<map_name>,<x>,<y>...}" \
  SET_START_POINT_PRE="Point where newly created character will start. Format: <map_name>,<x>,<y>{:<map_name>,<x>,<y>...}" \
  SET_START_POINT_DORAM="Point where a new character from Doram race will start. Format: <map_name>,<x>,<y>{:<map_name>,<x>,<y>...}" \
  SET_START_ITMES="Starting items for new characters. For auto-equip, include the position, otherwise 0. Format: <id>,<amount>,<position>{:<id>,<amount>,<position>" \
  SET_START_ITEMS_DORAM="Starting items for new character from Doram race." \
  SET_PINCODE_ENABLED="Whatever a PINCODE only inputable by mouse is asked to the player. If we are testing bots this should be disabled." \
  SET_ALLOWED_REGS="How many new characters registration are we going to allow per time unit." \
  SET_TIME_ALLOWED="Amount of time in seconds for allowing characters registration"

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
    apt-get install -y \
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
    linux-headers-generic

# Clone the rAthena repository at specific commit
RUN git clone https://github.com/rathena/rathena.git /opt/rAthena && \
    cd /opt/rAthena && \
    git checkout ${RATHENA_COMMIT}

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
        echo "Building for Classic/Pre-Renewal mode" && \
        ./configure --enable-packetver=${PACKETVER} --enable-prere=yes; \
    else \
        echo "Building for Renewal mode" && \
        ./configure --enable-packetver=${PACKETVER}; \
    fi \
    && make clean \
    && make server \
    && chmod a+x login-server char-server map-server web-server

# Copy additional files
COPY docker-entrypoint.sh /usr/local/bin/
COPY accountsandchars.sql /root/
COPY gab_npc.txt /opt/rAthena/npc/custom/

# Expose ports
EXPOSE 6900/tcp 6121/tcp 5121/tcp

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/opt/rAthena/athena-start", "watch"]
