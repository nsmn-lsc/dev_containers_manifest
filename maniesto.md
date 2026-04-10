# Manifiesto de Arquitectura de Desarrollo Atómica y Persistente

| Campo | Valor |
|---|---|
| **Proyecto** | Arquitectura de Desarrollo |
| **Autor** | LSC. Norel Sánchez Nájera |
| **Última actualización** | 2026-04-10 |
| **Estado** | Fase de Cimentación |

---

## 1. Visión General

Establecer una arquitectura de desarrollo **desacoplada, inmutable y reproducible**, capaz de sincronizarse entre múltiples dispositivos físicos sin pérdida de integridad, especialmente en entornos que manejan datos geoespaciales y de salud pública.

### Objetivos Estratégicos

- Paridad total de entornos entre equipos.
- Persistencia y consistencia de los datos.
- Reproducibilidad declarativa del sistema completo.
- Aislamiento controlado entre capas críticas (SO, datos, aplicación).

---

## 2. Stack Tecnológico — El "Qué"

| Capa | Herramientas | Rol |
|---|---|---|
| **Sistema Operativo (Host)** | Fedora Silverblue (Oficina) / Bazzite (Casa & Handheld) | Inmutabilidad del sistema base; elimina *configuration drift* y protege dependencias críticas |
| **Orquestación y Aislamiento** | Distrobox + Podman | Entornos mutables sobre host inmutable; motor *daemonless*, seguro y ligero |
| **Datos (`infra-db`)** | PostgreSQL 16+ / PostGIS | Single Source of Truth; Unix Domain Sockets para máximo rendimiento y mínima superficie de ataque |
| **Aplicación (`hidalgo-dev`)** | Python 3.12+ / Django / Leaflet.js | Capa dinámica que consume datos sin acoplarse al ciclo de vida de `infra-db` |

---

## 3. Arquitectura de Contenedores — El "Cómo"

### `infra-db` — Single Source of Truth

- Único contenedor autorizado para ejecutar PostgreSQL/PostGIS.
- **Persistencia:** volumen mapeado desde `${HOME}/.local/share/dbdata/`.
- **Comunicación:** sockets expuestos dentro del volumen para ser compartidos.

### Contenedores de aplicación (`hidalgo-dev`, etc.)

- Cada proyecto vive en su propio Distrobox.
- **Acceso a BD:** montaje en lectura/escritura del directorio de sockets de `infra-db` — los sockets Unix son bidireccionales; el acceso se controla a nivel de permisos del sistema de archivos (`chmod 700`), no de montaje.
- No exponen puertos innecesarios al stack de red.

---

## 4. Estrategia de Sincronización Multi-Dispositivo

**Herramienta:** Syncthing

| Nodo | Dispositivo | Rol |
|---|---|---|
| `silverblue` | Work | Principal |
| `asus-tuf` | Home | Secundario |
| `rog-ally` | Mobile | Consulta/Campo |

### Carpetas sincronizadas

| Ruta | Autoridad | Método |
|---|---|---|
| `~/Projects/hidalgo-health-stack/code` | Git | Git push/pull |
| `~/Projects/hidalgo-health-stack/docs` | Syncthing | Archivos de texto — seguro |
| `~/.local/share/dbdata` | **`pg_dump` / `pg_basebackup`** | ⚠️ Ver nota abajo |

> **⚠️ Nota sobre sincronización de datos:** Syncthing **no debe** sincronizar los binarios del cluster PostgreSQL (`$PGDATA`) directamente. Los archivos WAL y de control son altamente sensibles a sincronización parcial y pueden corromperse sin aviso. La estrategia correcta es transferir datos mediante herramientas propias de PostgreSQL:
>
> - **Datos lógicos:** `pg_dump -Fc dbname > backup.dump` → transferir con Syncthing → `pg_restore` en destino.
> - **Réplica completa del cluster:** `pg_basebackup -D /ruta/destino -Ft -z` con verificación de checksums.

### Protocolo de Traspaso ⚠️ Crítico

Para evitar corrupción por escrituras simultáneas:

1. **Equipo A:** ejecutar `stop_db.sh` y confirmar estado **Sincronizado (Verde)** en Syncthing.
2. **Equipo A:** generar dump: `pg_dump -Fc -d nombre_db > ~/sync/nombre_db_$(date +%F).dump`
3. **Equipo B:** confirmar que el dump está sincronizado y restaurar: `pg_restore -d nombre_db ~/sync/nombre_db_FECHA.dump`
4. **Equipo B:** ejecutar `start_db.sh`.

> **Requisito:** todos los nodos deben usar la **misma versión exacta** de PostgreSQL, PostGIS y extensiones cargadas en el cluster.

---

## 5. Scripts de Cimentación

### `start_db.sh`

```bash
#!/bin/bash
set -e
PGDATA="/var/lib/pgsql/data"
LOGFILE="${PGDATA}/server.log"

# Verificar si ya está corriendo antes de limpiar el PID
if pg_ctl -D "${PGDATA}" status &>/dev/null; then
  echo "PostgreSQL ya está en ejecución. Abortando."
  exit 0
fi

# Limpiar archivos huérfanos solo si el proceso no existe
rm -f "${PGDATA}/postmaster.pid"
rm -f "${PGDATA}/run/.s.PGSQL.5432"

# Arranque controlado con ruta de log absoluta
pg_ctl -D "${PGDATA}" -l "${LOGFILE}" start
echo "PostgreSQL iniciado. Log: ${LOGFILE}"
```

### `stop_db.sh`

```bash
#!/bin/bash
# Apagado rápido para liberar locks
pg_ctl -D /var/lib/pgsql/data stop -m fast
echo "Servicios detenidos. Listo para sincronización."
```

---

## 6. Consideraciones para el Proyecto de Salud Pública

| Aspecto | Detalle |
|---|---|
| **Optimización geográfica** | `infra-db` preprocesa capas SHP pesadas con `ogr2ogr`, reduciendo carga en la capa de aplicación |
| **Seguridad** | Los sockets restringen acceso local; `pg_hba.conf` usa `scram-sha-256` (no `md5`, deprecado en PG14+) y restringe conexiones TCP al rango de red de Podman (`10.88.0.0/16`) |
| **Integridad** | La sincronización controlada garantiza consistencia de datos epidemiológicos entre dispositivos |

---

## 7. Configuración de Seguridad (`pg_hba.conf`)

Reemplazar la línea permisiva `host all all all md5` por configuración restrictiva:

```conf
# Conexiones locales por socket — sin contraseña para el usuario del sistema
local   all             all                                     trust
# Conexiones TCP desde contenedores Podman/Distrobox
host    all             all             10.88.0.0/16            scram-sha-256
# Bloquear todo lo demás
host    all             all             0.0.0.0/0               reject
```

> `md5` está deprecado desde PostgreSQL 14. `scram-sha-256` es el estándar actual y resiste ataques de replay.

---

## 8. Estrategia de Backup

Syncthing **no es un mecanismo de backup**. Requiere política independiente:

| Tipo | Comando | Frecuencia sugerida |
|---|---|---|
| Dump lógico completo | `pg_dump -Fc -d nombre_db > backup_$(date +%F).dump` | Diario antes de traspaso |
| Backup físico del cluster | `pg_basebackup -D ~/backups/cluster -Ft -z -P` | Semanal |
| Verificación de integridad | `pg_restore --list backup.dump` | Tras cada dump |

> Los dumps deben almacenarse fuera de `$PGDATA` para que Syncthing los distribuya sin riesgo.

---

## 9. Versiones Requeridas

Todos los nodos deben tener instaladas las **mismas versiones exactas**:

| Componente | Versión mínima | Comando de verificación |
|---|---|---|
| PostgreSQL | 16.x | `psql --version` |
| PostGIS | 3.4.x | `SELECT PostGIS_full_version();` |
| `pg_dump` / `pg_restore` | Igual al servidor | `pg_dump --version` |

---

## 10. Ruta Crítica — Próximos Pasos

- [ ] Configurar el clúster de Syncthing entre los tres dispositivos.
- [ ] Validar la comunicación por sockets entre contenedores Distrobox distintos (montar directorio como rw, verificar `chmod 700`).
- [ ] Aplicar configuración de `pg_hba.conf` con `scram-sha-256` y restricción de red.
- [ ] Implementar y probar flujo de `pg_dump` → Syncthing → `pg_restore` entre dos nodos.
- [ ] Implementar el primer modelo de Django para vigilancia epidemiológica.
- [ ] Ejecutar prueba de estrés en la ROG Ally para ajustar recursos de PostgreSQL.