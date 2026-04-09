#!/usr/bin/env bash

echo "[infra-db] Ejecutando script de inicialización..."

# Inicializa cluster si no existe
if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
    echo "[infra-db] Inicializando cluster PostgreSQL..."
    postgresql-setup --initdb
fi

# Arranca PostgreSQL si no está corriendo
if ! pg_ctl -D /var/lib/pgsql/data status > /dev/null 2>&1; then
    echo "[infra-db] Iniciando PostgreSQL..."
    pg_ctl -D /var/lib/pgsql/data -l /tmp/postgres.log start
fi

echo "[infra-db] Inicialización completa."
