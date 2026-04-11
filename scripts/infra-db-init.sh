#!/usr/bin/env bash

PG_DATA="/var/lib/pgsql/data"
PG_LOG="${PG_DATA}/server.log"
PG_RUN="${PG_DATA}/run"

echo "🔍 Aplicando Runbook rootless de la Arquitectura de Desarrollo..."

# CRÍTICO: Aplicar permisos estrictos (Resuelve el "Permiso denegado")
chmod 700 "$PG_DATA"

# Paso 3 del Runbook: Inicialización
if [ ! -d "$PG_DATA/base" ]; then
    echo "🌱 Inicializando clúster..."
    initdb -D "$PG_DATA"

    # Paso 4 del Runbook: Configuración del socket rootless
    echo "🔧 Configurando socket rootless y red..."
    mkdir -p "$PG_RUN"
    chmod 700 "$PG_RUN"
    echo "unix_socket_directories = '$PG_RUN'" >> "$PG_DATA/postgresql.conf"
    
    # Pre-configuración del manifiesto (Seguridad)
    echo "listen_addresses = '*'" >> "$PG_DATA/postgresql.conf"
    echo "host all all 10.88.0.0/16 scram-sha-256" >> "$PG_DATA/pg_hba.conf"

    echo "✅ Clúster inicializado."
fi

# Garantizar que el directorio run exista en cada reinicio
mkdir -p "$PG_RUN"
chmod 700 "$PG_RUN"

# Paso 5 del Runbook: Arranque
echo "🚀 Iniciando motor de PostgreSQL..."
pg_ctl -D "$PG_DATA" -l "$PG_LOG" start

echo "📊 Estado del motor:"
pg_ctl -D "$PG_DATA" status