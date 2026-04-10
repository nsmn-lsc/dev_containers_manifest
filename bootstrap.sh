#!/usr/bin/env bash

set -e

echo "🧹 Limpiando metadata previa..."
rm -rf ~/.local/share/distrobox/infra-db || true

echo "🧹 Eliminando contenedor Podman previo (si existe)..."
podman rm -f infra-db 2>/dev/null || true

echo "🚀 Creando infraestructura Distrobox..."
distrobox assemble create --file distrobox.ini

echo "✔ Listo. Puedes entrar a la caja de BD con:"
echo "  distrobox enter infra-db"
