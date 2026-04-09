#!/usr/bin/env bash

echo "Creando y ensamblando infraestructura Distrobox..."
distrobox assemble create --file distrobox.ini

echo "Listo. Puedes entrar a la caja de BD con:"
echo "  distrobox enter infra-db"
echo "O a la caja de desarrollo con:"
echo "  distrobox enter dev-infra-db"