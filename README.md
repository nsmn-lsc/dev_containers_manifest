Infraestructura Declarativa para Contenedores de Desarrollo y Servicios en Distrobox

Este repositorio contiene la definición versionada, reproducible y modular de los contenedores Distrobox utilizados como infraestructura de desarrollo y servicios base en entornos como Bazzite, Fedora Silverblue, Fedora Kinoite y otros sistemas inmutables.

El objetivo es mantener un entorno limpio, portable y sin contaminación del host, donde cada contenedor cumple un rol específico dentro del laboratorio de desarrollo.
🚀 Objetivos del Proyecto

    Mantener una infraestructura declarativa para contenedores Distrobox.

    Permitir reconstruir el entorno completo en cualquier máquina con un solo comando.

    Centralizar servicios críticos como PostgreSQL + PostGIS en una caja dedicada.

    Separar entornos de desarrollo por proyecto (ej. dev-salud-hidalgo).

    Garantizar reproducibilidad entre equipos personales, de trabajo o servidores.

    Facilitar rollback mediante versionado con Git y tags semánticos.

🧩 Contenedores Declarados

Este repositorio define actualmente dos contenedores:
1. infra-db — Infraestructura de Base de Datos

Contenedor dedicado a:

    PostgreSQL

    PostGIS

    GDAL / GEOS / PROJ

    Volumen persistente para datos geoespaciales

Funciona como servidor de bases de datos central para todos los demás contenedores Distrobox.
Características:

    Inicialización automática del cluster si no existe.

    Arranque automático del servicio al entrar.

    Volumen persistente en ${HOME}/.local/share/dbdata.

    Ideal para proyectos GIS, FastAPI, Django, análisis, etc.

2. dev-salud-hidalgo — Entorno de Desarrollo

Contenedor para el desarrollo del proyecto:

    Backend (FastAPI)

    Frontend (Node.js / SvelteKit / React)

    Procesamiento de datos (Pandas / GeoPandas)

    GIS (GDAL, PROJ, GEOS)

Incluye instalación automática de dependencias Python.
📦 Estructura del Repositorio
Código

dev_containers_manifest/
├── README.md
├── distrobox.ini
├── bootstrap.sh
├── containers/
│   ├── infra-db/
│   │   ├── notes.md
│   │   └── config.md
│   └── dev-salud-hidalgo/
│       ├── notes.md
│       └── config.md
└── scripts/
    ├── backup_db.sh
    ├── restore_db.sh
    └── check_status.sh

⚙️ Instalación y Uso
1. Clonar el repositorio
Código

git clone git@github.com:nsmn-lsc/dev_containers_manifest.git
cd dev_containers_manifest

2. Ensamblar los contenedores declarados
Código

./bootstrap.sh

Esto ejecuta:

    distrobox assemble create --file distrobox.ini

    Crea o reemplaza los contenedores declarados

    Inicializa PostgreSQL si es la primera vez

    Arranca el servicio automáticamente

3. Entrar a los contenedores
Base de datos:
Código

distrobox enter infra-db

Entorno de desarrollo:
Código

distrobox enter dev-salud-hidalgo

🗄️ Persistencia de Datos

Los datos de PostgreSQL se almacenan en:
Código

${HOME}/.local/share/dbdata

Esto permite:

    destruir y recrear la Distrobox sin perder datos

    migrar el volumen entre máquinas

    hacer backups simples

🔁 Versionado y Releases

Cada cambio en la infraestructura debe versionarse:
Código

git add .
git commit -m "Descripción del cambio"
git tag -a v1.1 -m "Nueva versión"
git push --tags

Esto permite:

    reconstruir versiones anteriores

    mantener historial claro

    reproducir entornos exactos en otras máquinas

🧪 Reconstrucción de una versión específica
Código

git checkout v1.0
./bootstrap.sh

🛡️ Buenas Prácticas

    Mantener los contenedores pequeños y especializados.

    No instalar herramientas innecesarias en infra-db.

    Mantener los volúmenes fuera del contenedor.

    Versionar siempre que se modifique distrobox.ini.

    Usar tags semánticos (v1.0, v1.1, v2.0).

🛰️ Requisitos del Sistema

    Bazzite, Fedora Silverblue, Kinoite o cualquier sistema con Podman + Distrobox

    Podman 4+

    Distrobox 1.6+