# Docker Compose Quick Start Guide

This guide helps you run rAthena locally using Docker Compose.

## Prerequisites

- Docker installed (version 20.10+)
- Docker Compose installed (version 2.0+)
- At least 2GB of free RAM
- Ports 3306, 5121, 6121, 6900, 8888 available

## Quick Start

### 1. Start the server

```bash
# Using the local compose file
docker-compose -f docker-compose.local.yaml up -d

# Or if you want to see logs in real-time
docker-compose -f docker-compose.local.yaml up
```

### 2. Wait for initialization (first run)

The first time you run this, it will:
- Download the Docker images (~1GB)
- Create the MySQL database
- Import SQL tables
- Create 2 GM accounts + 5000 test bot accounts

**This takes 2-3 minutes on first run.** Watch the logs:

```bash
docker-compose -f docker-compose.local.yaml logs -f rathena-renewal
```

Look for these success messages:
```
[Status]: The login-server is ready (Server is listening on the port 6900).
[Status]: The char-server is ready (Server is listening on the port 6121).
[Status]: Server is 'ready' and listening on port '5121'.
```

### 3. Check server status

```bash
# View logs
docker-compose -f docker-compose.local.yaml logs -f

# Check if servers are running
docker-compose -f docker-compose.local.yaml ps
```

## Test Accounts

After initialization, these accounts are created:

| Type | Username | Password | Access Level |
|------|----------|----------|--------------|
| GM Account 1 | gm1 | gm1 | 99 (Admin) |
| GM Account 2 | gm2 | gm2 | 99 (Admin) |
| Bot Accounts | bot0000-bot4999 | bot | 0 (Player) |

Each bot account has 1 pre-created character with random stats and equipment.

## Configuration

### Change Server Mode (Renewal/Classic)

Edit `docker-compose.local.yaml`:

```yaml
# For Renewal (default)
environment:
  SERVER_MODE: renewal
  RENEWAL: "true"

# For Classic/Pre-Renewal
environment:
  SERVER_MODE: classic
  RENEWAL: "false"
```

### Change Public IP (for external access)

By default, servers use `127.0.0.1` (localhost only).

For LAN/external access:

```yaml
environment:
  SET_CHAR_PUBLIC_IP: 192.168.1.100  # Your host's IP
  SET_MAP_PUBLIC_IP: 192.168.1.100
```

### Change Database Password

```yaml
mysql:
  environment:
    MYSQL_PASSWORD: your-secure-password

rathena-renewal:
  environment:
    MYSQL_PASSWORD: your-secure-password
```

### Reset Database

To recreate the database from scratch:

```yaml
environment:
  MYSQL_DROP_DB: 1  # Will drop and recreate database on next start
```

**OR** manually:

```bash
# Stop services
docker-compose -f docker-compose.local.yaml down

# Remove database volume
docker volume rm docker-rathena_mysql-data

# Start again
docker-compose -f docker-compose.local.yaml up -d
```

## Common Commands

```bash
# Start services
docker-compose -f docker-compose.local.yaml up -d

# Stop services
docker-compose -f docker-compose.local.yaml down

# View logs
docker-compose -f docker-compose.local.yaml logs -f

# Restart a service
docker-compose -f docker-compose.local.yaml restart rathena-renewal

# Access MySQL directly
docker-compose -f docker-compose.local.yaml exec mysql mysql -u rathena -prathena_pass rathena_renewal

# Execute commands in rathena container
docker-compose -f docker-compose.local.yaml exec rathena-renewal bash

# Update to latest image
docker-compose -f docker-compose.local.yaml pull
docker-compose -f docker-compose.local.yaml up -d
```

## Troubleshooting

### Servers not connecting to each other

**Symptoms:**
- `[Error]: Can not connect to login-server`
- `[Error]: make_connection: connect failed`

**Fix:**
1. Check logs: `docker-compose -f docker-compose.local.yaml logs mysql`
2. Verify MySQL is healthy: `docker-compose -f docker-compose.local.yaml ps`
3. Restart services: `docker-compose -f docker-compose.local.yaml restart`

### Database tables missing

**Symptoms:**
- `[SQL]: DB error - Table 'rathena_renewal.login' doesn't exist`

**Fix:**
Set `MYSQL_DROP_DB: 1` to force recreation, then restart.

### Wrong game mode (Renewal vs Classic)

**Symptoms:**
- Loading `db/pre-re/` when you want Renewal
- Loading `db/re/` when you want Classic

**Fix:**
Check environment variables:
```bash
docker-compose -f docker-compose.local.yaml exec rathena-renewal printenv | grep RENEWAL
```

Should show: `RENEWAL=true` for Renewal, `RENEWAL=false` for Classic.

### Port conflicts

**Symptoms:**
- `bind: address already in use`

**Fix:**
Change port mappings in `docker-compose.local.yaml`:
```yaml
ports:
  - "7900:6900"  # Use different host port
```

## Connecting with a Client

1. Download a Ragnarok Online client (matching your packet version: 20200401)
2. Edit `clientinfo.xml` or `sclientinfo.xml`:
   ```xml
   <address>127.0.0.1</address>
   <port>6900</port>
   <version>55</version>
   <langtype>1</langtype>
   <loading>
     <image>loading00.jpg</image>
   </loading>
   ```
3. Run the client
4. Login with `gm1` / `gm1`

## Advanced: Running Both Renewal and Classic

Uncomment the `rathena-classic` service in `docker-compose.local.yaml` to run both modes simultaneously on different ports.

## Clean Up

To completely remove everything:

```bash
# Stop and remove containers
docker-compose -f docker-compose.local.yaml down

# Remove volumes (deletes database)
docker-compose -f docker-compose.local.yaml down -v

# Remove images
docker rmi ghcr.io/lenaxia/docker-rathena:renewal-latest
docker rmi ghcr.io/lenaxia/docker-rathena:classic-latest
```

## Support

- GitHub Issues: https://github.com/lenaxia/docker-rathena/issues
- rAthena Documentation: https://github.com/rathena/rathena/wiki
