🧱 PostgreSQL rootless en Distrobox (Fedora/Bazzite) — Guía Definitiva

Esta guía documenta cómo inicializar, configurar y ejecutar PostgreSQL en un contenedor Distrobox rootless, especialmente en sistemas como Bazzite, Fedora Silverblue/Kinoite, o cualquier entorno OSTree donde los contenedores rootful fallan.
🧩 1. Contexto del entorno

    El contenedor se ejecuta rootless (obligatorio en Bazzite).
    PostgreSQL se instala dentro del contenedor.
    El usuario del sistema (ej. najera) se convierte en el superusuario inicial del cluster.
    No existe el usuario postgres del sistema.
    No existe /var/run/postgresql (tmpfs del host → no accesible rootless).
    El socket debe moverse a un directorio controlado por el usuario.



🧩 2. Instalar PostgreSQL dentro del contenedor
bash

sudo dnf install postgresql-server postgresql-contrib -y

Verificar:
bash

which postgres

🧩 3. Preparar el directorio de datos

Crear y asignar permisos correctos:
bash

sudo mkdir -p /var/lib/pgsql/data
sudo chown -R $USER:$USER /var/lib/pgsql
chmod 700 /var/lib/pgsql
chmod 700 /var/lib/pgsql/data

🧩 4. Inicializar el cluster
bash

initdb -D /var/lib/pgsql/data

Esto crea:

    postgresql.conf
    pg_hba.conf
    base/
    global/
    pg_wal/


🧩 5. Configurar el socket para entornos rootless

Crear directorio alternativo:
bash

mkdir -p /var/lib/pgsql/data/run
chmod 700 /var/lib/pgsql/data/run

Editar postgresql.conf:
bash

unix_socket_directories = '/var/lib/pgsql/data/run'


🧩 6. Arrancar PostgreSQL sin systemd
bash

pg_ctl -D /var/lib/pgsql/data -l logfile start

Verificar:
bash

pg_ctl -D /var/lib/pgsql/data status

🧩 7. Conectarse al servidor

El superusuario inicial es el usuario del sistema (ej. najera).

Conexión por TCP:
bash

psql -h localhost -U najera postgres

Conexión por socket:
bash

psql -h /var/lib/pgsql/data/run -U najera postgres


🧩 8. Crear el rol “postgres” (opcional pero recomendado)

Dentro de psql:
sql

CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD 'tu_password';

🧩 9. Crear bases necesarias
sql

CREATE DATABASE postgres OWNER postgres;
CREATE DATABASE najera OWNER najera;

🧩 10. Habilitar conexiones externas (otros contenedores)

Editar postgresql.conf:
bash

listen_addresses = '*'

Editar pg_hba.conf:
bash

host all all all md5

Reiniciar:
bash

pg_ctl -D /var/lib/pgsql/data restart

🧩 11. Conexión desde otros contenedores Distrobox

Usar:
Código

host=host.containers.internal
port=5432
user=postgres
password=tu_password
dbname=lo_que_necesites


🧩 12. Estructura recomendada de scripts
start-postgres.sh
bash

#!/usr/bin/env bash
pg_ctl -D /var/lib/pgsql/data -l logfile start

stop-postgres.sh
bash

#!/usr/bin/env bash
pg_ctl -D /var/lib/pgsql/data stop