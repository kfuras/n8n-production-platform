#!/bin/bash

# Connect NocoDB to Supabase Postgres on Docker Compose internal network (no SSL)
# ============================================================

set -e

echo "# Connect NocoDB to Supabase Postgres on internal network (no SSL)"
echo "# ============================================================"
echo ""

# 1. Identify container names
echo "1. Identifying container names..."
NOCO_CONTAINER=$(docker ps --format '{{.Names}}' | grep 'nocodb' | head -n 1)
PG_CONTAINER=$(docker ps --format '{{.Names}}' | grep 'supabase-db' | head -n 1)

if [ -z "$NOCO_CONTAINER" ] || [ -z "$PG_CONTAINER" ]; then
    echo "❌ Could not find NocoDB or Supabase Postgres container."
    echo "Make sure both are running."
    exit 1
fi

echo "✅ Found containers:"
echo "  NocoDB:    $NOCO_CONTAINER"
echo "  Postgres:  $PG_CONTAINER"
echo ""

# 2. Get network name for Postgres
echo "2. Getting network name for Postgres..."
PG_NET=$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' "$PG_CONTAINER")
echo "📋 Postgres network: $PG_NET"
echo ""

# 3. Connect NocoDB container to Postgres network (if not already)
echo "3. Connecting NocoDB to Postgres network..."
if docker network inspect "$PG_NET" | grep -q "$NOCO_CONTAINER"; then
    echo "✅ Done! NocoDB is already on the same network as Postgres."
else
    docker network connect "$PG_NET" "$NOCO_CONTAINER"
    echo "✅ Connected NocoDB to Postgres network."
fi

echo ""

# 4. Get Postgres internal IP
PG_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$PG_CONTAINER")
echo "📋 Postgres internal IP: $PG_IP"
echo ""

# 5. Output settings for NocoDB GUI (use env vars from .env)
echo "════════════════════════════════════════════════════════"
echo "✅ USE THESE SETTINGS IN NOCODB GUI:"
echo "════════════════════════════════════════════════════════"
echo "Host address : supabase-db"
echo "Port         : 5432"
echo "Username     : ${NOCODB_USER:-nocodb_user}"
echo "Password     : [See .env file - NOCODB_PASSWORD]"
echo "Database     : ${NOCODB_DB:-nocodb}"
echo "SSL          : Disabled"
echo ""
echo "Or use connection string from .env:"
echo "pg://${NOCODB_USER}:${NOCODB_PASSWORD}@supabase-db:5432/${NOCODB_DB}"
echo "════════════════════════════════════════════════════════"