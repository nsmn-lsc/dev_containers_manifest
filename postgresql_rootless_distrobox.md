# Runbook — PostgreSQL rootless en Distrobox (Fedora/Bazzite)

**Objetivo:** Inicializar, configurar y levantar PostgreSQL dentro de un contenedor Distrobox rootless.  
**Aplica a:** Bazzite, Fedora Silverblue/Kinoite y entornos OSTree donde el modo rootful falla.  
**Prerequisito:** Estar dentro del contenedor Distrobox antes de ejecutar cualquier paso.

---

## Contexto del entorno

| Condición | Valor |
|---|---|
| Modo de contenedor | Rootless (obligatorio en Bazzite) |
| Superusuario inicial del cluster | Tu usuario del sistema (ej. `najera`) |
| Usuario `postgres` del sistema | No existe |
| `/var/run/postgresql` | No accesible (tmpfs del host) |
| Socket | Debe estar en un directorio propio del usuario |

---

## Paso 1 — Instalar PostgreSQL

- [ ] Instalar paquetes:

```bash
sudo dnf install postgresql-server postgresql-contrib -y
```

- [ ] Verificar que el binario está disponible:

```bash
which postgres
# Esperado: /usr/bin/postgres
```

---

## Paso 2 — Preparar el directorio de datos

- [ ] Crear el directorio y asignar permisos:

```bash
sudo mkdir -p /var/lib/pgsql/data
sudo chown -R "$USER":"$USER" /var/lib/pgsql
chmod 700 /var/lib/pgsql
chmod 700 /var/lib/pgsql/data
```

- [ ] Verificar permisos:

```bash
ls -ld /var/lib/pgsql/data
# Esperado: drwx------ ... najera najera ...
```

---

## Paso 3 — Inicializar el cluster

- [ ] Ejecutar `initdb`:

```bash
initdb -D /var/lib/pgsql/data
```

- [ ] Confirmar que se generaron los archivos del cluster:

```bash
ls /var/lib/pgsql/data
# Esperado: postgresql.conf  pg_hba.conf  base/  global/  pg_wal/  ...
```

---

## Paso 4 — Configurar el socket (rootless)

- [ ] Crear directorio para el socket:

```bash
mkdir -p /var/lib/pgsql/data/run
chmod 700 /var/lib/pgsql/data/run
```

- [ ] Editar `postgresql.conf` para apuntar el socket al nuevo directorio:

```conf
unix_socket_directories = '/var/lib/pgsql/data/run'
```

---

## Paso 5 — Arrancar PostgreSQL sin systemd

- [ ] Iniciar el servidor:

```bash
pg_ctl -D /var/lib/pgsql/data -l logfile start
```

- [ ] Verificar que está corriendo:

```bash
pg_ctl -D /var/lib/pgsql/data status
# Esperado: pg_ctl: server is running (PID: ...)
```

---

## Paso 6 — Primera conexión

El superusuario inicial es tu usuario del sistema.

- [ ] Conectar por TCP:

```bash
psql -h localhost -U najera postgres
```

- [ ] O conectar por socket:

```bash
psql -h /var/lib/pgsql/data/run -U najera postgres
```

---

## Paso 7 — Crear el rol `postgres` (recomendado)

- [ ] Dentro de `psql`, ejecutar:

```sql
CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD 'tu_password';
```

---

## Paso 8 — Crear bases de datos necesarias

- [ ] Ejecutar en `psql`:

```sql
CREATE DATABASE postgres OWNER postgres;
CREATE DATABASE najera OWNER najera;
```

---

## Paso 9 — Habilitar conexiones externas

- [ ] En `postgresql.conf`, configurar:

```conf
listen_addresses = '*'
```

- [ ] En `pg_hba.conf`, agregar:

```conf
host all all all md5
```

- [ ] Reiniciar el servidor para aplicar cambios:

```bash
pg_ctl -D /var/lib/pgsql/data restart
```

- [ ] Verificar estado tras el reinicio:

```bash
pg_ctl -D /var/lib/pgsql/data status
```

---

## Paso 10 — Conectar desde otros contenedores Distrobox

Parámetros de conexión a usar en el cliente o aplicación:

```ini
host=host.containers.internal
port=5432
user=postgres
password=tu_password
dbname=lo_que_necesites
```

---

## Scripts de operación diaria

**`start-postgres.sh`**

```bash
#!/usr/bin/env bash
pg_ctl -D /var/lib/pgsql/data -l logfile start
```

**`stop-postgres.sh`**

```bash
#!/usr/bin/env bash
pg_ctl -D /var/lib/pgsql/data stop
```

---

## Referencia rápida de comandos

| Acción | Comando |
|---|---|
| Iniciar | `pg_ctl -D /var/lib/pgsql/data -l logfile start` |
| Detener | `pg_ctl -D /var/lib/pgsql/data stop` |
| Reiniciar | `pg_ctl -D /var/lib/pgsql/data restart` |
| Estado | `pg_ctl -D /var/lib/pgsql/data status` |
| Conectar (TCP) | `psql -h localhost -U najera postgres` |
| Conectar (socket) | `psql -h /var/lib/pgsql/data/run -U najera postgres` |