#!/usr/bin/env bash

DUMP_DIR="${HOME}/.local/share/dbdata/dumps"
DB_NAME="zoonosis"
DUMP_FILE="$DUMP_DIR/${DB_NAME}_sync.dump"

echo "🔍 Buscando datos sincronizados en $DUMP_FILE..."

if [ ! -f "$DUMP_FILE" ]; then
    echo "⚠️ No se encontró archivo de sincronización. Abortando."
    exit 1
fi

echo "⚠️ ADVERTENCIA: Esto sobrescribirá la base de datos '$DB_NAME' actual."
read -p "¿Estás seguro de continuar? (s/N): " confirm

if [[ "$confirm" =~ ^[sS]$ ]]; then
    echo "🧹 Limpiando base de datos anterior..."
    # Expulsar conexiones activas y recrear la base de datos limpia
    psql -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME';"
    psql -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
    psql -d postgres -c "CREATE DATABASE $DB_NAME OWNER $USER;"

    echo "🌱 Restaurando datos desde Syncthing..."
    # pg_restore inyecta el volcado lógico
    pg_restore -d "$DB_NAME" "$DUMP_FILE"
    
    echo "✅ Sincronización completada con éxito. Entorno actualizado."
else
    echo "❌ Operación cancelada."
fi