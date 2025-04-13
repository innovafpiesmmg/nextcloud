#!/bin/bash

# Script para descargar e instalar el instalador web de Nextcloud
# Autor: ChatGPT
# Fecha: 2023

# Colores para mensajes
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[0;33m'
RESET='\033[0m'

# Función para mostrar mensajes de error y salir
mostrar_error() {
    echo -e "${ROJO}[ERROR]${RESET} $1"
    exit 1
}

# Función para mostrar mensajes informativos
mostrar_info() {
    echo -e "${VERDE}[INFO]${RESET} $1"
}

# Función para mostrar advertencias
mostrar_advertencia() {
    echo -e "${AMARILLO}[ADVERTENCIA]${RESET} $1"
}

# Función para verificar dependencias
verificar_dependencias() {
    mostrar_info "Verificando dependencias necesarias..."
    
    # Verificar si está instalado curl o wget
    if command -v curl &> /dev/null; then
        DESCARGADOR="curl"
        mostrar_info "Se utilizará curl para la descarga."
    elif command -v wget &> /dev/null; then
        DESCARGADOR="wget"
        mostrar_info "Se utilizará wget para la descarga."
    else
        mostrar_error "Se requiere curl o wget para la descarga. Por favor, instale alguno de estos programas."
    fi

    # Verificar si unzip está instalado
    if ! command -v unzip &> /dev/null; then
        mostrar_advertencia "No se detectó unzip, que puede ser necesario para descomprimir archivos."
        read -p "¿Desea continuar sin unzip? (s/n): " respuesta
        if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
            mostrar_error "Instalación cancelada. Por favor, instale unzip antes de continuar."
        fi
    fi
}

# Función para descargar el instalador web de Nextcloud
descargar_nextcloud() {
    mostrar_info "Iniciando descarga del instalador web de Nextcloud..."
    
    # URL del instalador web de Nextcloud
    URL_NEXTCLOUD="https://download.nextcloud.com/server/installer/setup-nextcloud.php"
    ARCHIVO_DESTINO="setup-nextcloud.php"
    
    if [ "$DESCARGADOR" = "curl" ]; then
        curl -# -L -o "$ARCHIVO_DESTINO" "$URL_NEXTCLOUD" || mostrar_error "Falló la descarga con curl."
    else
        wget --show-progress -O "$ARCHIVO_DESTINO" "$URL_NEXTCLOUD" || mostrar_error "Falló la descarga con wget."
    fi
    
    # Verificar si el archivo se descargó correctamente
    if [ -f "$ARCHIVO_DESTINO" ]; then
        # Verificar el tamaño del archivo (debe ser mayor a 0 bytes)
        if [ -s "$ARCHIVO_DESTINO" ]; then
            mostrar_info "Instalador web de Nextcloud descargado correctamente."
            # Establecer permisos adecuados
            chmod 755 "$ARCHIVO_DESTINO"
        else
            mostrar_error "El archivo descargado está vacío. Verifique su conexión a Internet y vuelva a intentarlo."
        fi
    else
        mostrar_error "No se pudo encontrar el archivo descargado."
    fi
}

# Función para mostrar instrucciones post-descarga
mostrar_instrucciones() {
    echo ""
    echo "=============================================================="
    echo "                INSTALADOR WEB DE NEXTCLOUD                   "
    echo "=============================================================="
    echo ""
    mostrar_info "El instalador web de Nextcloud se ha descargado correctamente."
    echo ""
    mostrar_info "Para completar la instalación, siga estos pasos:"
    echo ""
    echo "1. Mueva el archivo setup-nextcloud.php a la raíz de su servidor web."
    echo "   Por ejemplo: mv setup-nextcloud.php /var/www/html/"
    echo ""
    echo "2. Asegúrese de que su servidor web (Apache/Nginx) esté en funcionamiento."
    echo ""
    echo "3. Acceda al instalador desde su navegador web:"
    echo "   http://su-servidor/setup-nextcloud.php"
    echo ""
    echo "4. Siga las instrucciones en pantalla para completar la instalación."
    echo ""
    mostrar_advertencia "Requisitos importantes del sistema:"
    echo "- PHP 7.4 o superior"
    echo "- Base de datos MySQL/MariaDB, PostgreSQL o SQLite"
    echo "- Al menos 512MB de RAM"
    echo "- Permisos de escritura en el directorio donde se instalará Nextcloud"
    echo ""
    mostrar_info "Para más información, visite: https://docs.nextcloud.com/"
    echo ""
    echo "=============================================================="
}

# Función principal
main() {
    echo "=============================================================="
    echo "          INSTALADOR DEL INSTALADOR WEB DE NEXTCLOUD          "
    echo "=============================================================="
    echo ""
    
    verificar_dependencias
    descargar_nextcloud
    mostrar_instrucciones
}

# Ejecutar la función principal
main
