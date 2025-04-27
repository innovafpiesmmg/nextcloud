#!/bin/bash

# install_nextcloud_aio.sh
# Script para preparar un servidor Ubuntu (en Proxmox LXC) e iniciar
# la instalación de Nextcloud All-in-One (AIO).

# --- Configuración ---
# Asegúrate de que este script se ejecuta con privilegios de root o sudo.
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# Salir inmediatamente si un comando falla
set -e

# --- Actualización del Sistema ---
echo ">>> Actualizando paquetes del sistema..."
apt-get update
apt-get upgrade -y
echo ">>> Actualización completada."
echo ""

# --- Instalación de Docker ---
# AIO requiere Docker para funcionar.
echo ">>> Instalando Docker..."
if ! command -v docker &> /dev/null; then
    # Instalar dependencias necesarias
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

    # Añadir la clave GPG oficial de Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Añadir el repositorio de Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Instalar Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo ">>> Docker instalado correctamente."
else
    echo ">>> Docker ya está instalado."
fi
echo ""

# --- Comprobar estado de Docker ---
echo ">>> Verificando el servicio Docker..."
systemctl is-active --quiet docker || systemctl start docker
systemctl enable docker
echo ">>> Servicio Docker activo y habilitado."
echo ""

# --- Descargar e Iniciar Nextcloud AIO Mastercontainer ---
# Este comando descarga el contenedor principal de AIO y lo inicia.
# La configuración posterior se realiza a través de la interfaz web.
echo ">>> Descargando e iniciando el contenedor maestro de Nextcloud AIO..."
# Comprueba si el contenedor ya existe para evitar errores si se ejecuta de nuevo
if docker ps -a --format '{{.Names}}' | grep -q '^nextcloud-aio-mastercontainer$'; then
    echo ">>> El contenedor 'nextcloud-aio-mastercontainer' ya existe. Iniciándolo si está detenido..."
    docker start nextcloud-aio-mastercontainer
else
    echo ">>> Ejecutando el comando de inicio de Nextcloud AIO..."
    # Nota: Puedes necesitar ajustar el puerto 8080 si está en uso por otro servicio.
    docker run \
    --sig-proxy=false \
    --name nextcloud-aio-mastercontainer \
    --restart always \
    --publish 80:80 \
    --publish 8080:8080 \
    --publish 8443:8443 \
    --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    nextcloud/all-in-one:latest
fi

echo ""
echo ">>> ¡Proceso de inicio de Nextcloud AIO completado!"
echo ">>> Ahora debes acceder a la interfaz web de AIO para continuar la configuración."
echo ">>> Abre tu navegador y ve a https://<IP_DEL_SERVIDOR>:8080 o https://<TU_DOMINIO>:8443 (si ya has configurado un proxy inverso)."
echo ">>> Sigue las instrucciones en pantalla."
echo ""

exit 0
