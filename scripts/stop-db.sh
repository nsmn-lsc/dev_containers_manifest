#!/usr/bin/env bash

PG_DATA="${HOME}/.local/share/dbdata/postgres"
DUMP_DIR="${HOME}/.local/share/dbdata/dumps"
# Cambia 'zoonosis' por el nombre de tu base de datos principal de desarrollo
DB_NAME="zoonosis" 

# Asegurar que la carpeta de sincronización exista
mkdir -p "$DUMP_DIR"

echo "📦 Generando volcado lógico (Backup) de la base de datos '$DB_NAME'..."
# Se utiliza pg_dump con formato custom (-Fc) para empaquetamiento eficiente
pg_dump -Fc -d "$DB_NAME" -f "$DUMP_DIR/${DB_NAME}_sync.dump"

echo "🛑 Iniciando apagado seguro del clúster de PostgreSQL..."
pg_ctl -D "$PG_DATA" stop

echo "✅ Motor detenido."
echo "🔄 El archivo ${DB_NAME}_sync.dump está listo para ser sincronizado por Syncthing."listo,