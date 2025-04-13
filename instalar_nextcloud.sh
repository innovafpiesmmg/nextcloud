#!/bin/bash

# Script para descargar e instalar Nextcloud desde GitHub
# Autor: ChatGPT
# Fecha: 2023
# Versión: 1.1

# Colores para mensajes
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[0;33m'
AZUL='\033[0;34m'
RESET='\033[0m'

# Configuración de la instalación
REPO_GITHUB="https://github.com/innovafpiesmmg/nextcloud"
DIRECTORIO_INSTALACION="nextcloud"
VERSION_TAG="latest"  # Puedes configurar para descargar una versión específica
IDIOMA="es"  # Idioma predeterminado, puede ser cambiado por el usuario

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

# Función para mostrar pasos o acciones
mostrar_paso() {
    echo -e "${AZUL}[PASO]${RESET} $1"
}

# Función para mostrar el progreso
mostrar_progreso() {
    local pid=$1
    local mensaje=$2
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 8 ))
        printf "\r${VERDE}[%c]${RESET} %s" "${spin:$i:1}" "$mensaje"
        sleep 0.1
    done
    printf "\r${VERDE}[✓]${RESET} %s\n" "$mensaje"
}

# Función para verificar dependencias
verificar_dependencias() {
    mostrar_paso "Verificando dependencias necesarias..."
    
    # Verificar si está instalado git
    if ! command -v git &> /dev/null; then
        mostrar_error "Se requiere Git para clonar el repositorio. Por favor, instale Git antes de continuar."
    else
        mostrar_info "Git está instalado correctamente."
    fi
    
    # Verificar si está instalado curl o wget
    if command -v curl &> /dev/null; then
        DESCARGADOR="curl"
        mostrar_info "Se utilizará curl para las descargas adicionales si son necesarias."
    elif command -v wget &> /dev/null; then
        DESCARGADOR="wget"
        mostrar_info "Se utilizará wget para las descargas adicionales si son necesarias."
    else
        mostrar_advertencia "No se detectó curl o wget. Algunas funcionalidades podrían no estar disponibles."
    fi

    # Verificar si unzip está instalado
    if ! command -v unzip &> /dev/null; then
        mostrar_advertencia "No se detectó unzip, que puede ser necesario para descomprimir archivos."
        read -p "¿Desea continuar sin unzip? (s/n): " respuesta
        if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
            mostrar_error "Instalación cancelada. Por favor, instale unzip antes de continuar."
        fi
    else
        mostrar_info "Unzip está instalado correctamente."
    fi
    
    # Verificar requisitos para Nextcloud
    mostrar_info "Verificando requisitos para Nextcloud..."
    
    # Verificar PHP
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php -r 'echo PHP_VERSION;')
        mostrar_info "PHP versión $PHP_VERSION está instalado."
        
        # Verificar versión de PHP (se recomienda 7.4 o superior)
        if [[ "$(php -r 'echo version_compare(PHP_VERSION, "7.4.0", ">=") ? "1" : "0";')" == "0" ]]; then
            mostrar_advertencia "Se recomienda PHP 7.4 o superior para Nextcloud."
        fi
    else
        mostrar_advertencia "No se detectó PHP. Nextcloud requiere PHP 7.4 o superior."
    fi
    
    # Verificar servidor web
    if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
        mostrar_info "Se detectó Apache instalado."
    elif command -v nginx &> /dev/null; then
        mostrar_info "Se detectó Nginx instalado."
    else
        mostrar_advertencia "No se detectó ningún servidor web (Apache/Nginx). Nextcloud requiere un servidor web."
    fi
}

# Función para clonar/descargar Nextcloud desde GitHub
descargar_nextcloud() {
    mostrar_paso "Descargando Nextcloud desde GitHub..."
    
    # Verificar si el directorio de destino ya existe
    if [ -d "$DIRECTORIO_INSTALACION" ]; then
        mostrar_advertencia "El directorio '$DIRECTORIO_INSTALACION' ya existe."
        read -p "¿Desea sobrescribir el directorio existente? (s/n): " respuesta
        if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
            mostrar_error "Instalación cancelada por el usuario."
        fi
        rm -rf "$DIRECTORIO_INSTALACION"
    fi
    
    # Clonar el repositorio
    mostrar_info "Clonando repositorio de Nextcloud desde $REPO_GITHUB..."
    git clone "$REPO_GITHUB" "$DIRECTORIO_INSTALACION" &> /dev/null &
    PID=$!
    
    # Mostrar indicador de progreso mientras se clona
    mostrar_progreso $PID "Clonando repositorio de Nextcloud..."
    
    # Verificar si se clonó correctamente
    if [ $? -eq 0 ] && [ -d "$DIRECTORIO_INSTALACION" ]; then
        mostrar_info "Repositorio de Nextcloud clonado correctamente."
        
        # Cambiar al directorio del repositorio
        cd "$DIRECTORIO_INSTALACION" || mostrar_error "No se pudo acceder al directorio de instalación."
        
        # Si se especificó una versión específica, cambiar a esa etiqueta/rama
        if [ "$VERSION_TAG" != "latest" ]; then
            mostrar_info "Cambiando a la versión $VERSION_TAG..."
            git checkout "$VERSION_TAG" &> /dev/null || mostrar_advertencia "No se pudo cambiar a la versión $VERSION_TAG. Se usará la versión por defecto."
        fi
        
        cd ..
    else
        mostrar_error "Error al clonar el repositorio de Nextcloud. Verifique su conexión a Internet y los permisos."
    fi
}

# Función para configurar Nextcloud
configurar_nextcloud() {
    mostrar_paso "Configurando Nextcloud..."
    
    # Verificar si el directorio de instalación existe
    if [ ! -d "$DIRECTORIO_INSTALACION" ]; then
        mostrar_error "No se encontró el directorio de instalación de Nextcloud."
    fi
    
    # Establecer permisos adecuados
    mostrar_info "Estableciendo permisos adecuados..."
    find "$DIRECTORIO_INSTALACION" -type f -exec chmod 644 {} \;
    find "$DIRECTORIO_INSTALACION" -type d -exec chmod 755 {} \;
    
    # Configurar idioma si está disponible
    if [ -f "$DIRECTORIO_INSTALACION/config/config.php.example" ]; then
        mostrar_info "Configurando idioma predeterminado a '$IDIOMA'..."
        cp "$DIRECTORIO_INSTALACION/config/config.php.example" "$DIRECTORIO_INSTALACION/config/config.php"
        # Aquí se podría añadir la configuración del idioma en el archivo config.php
    fi
    
    # Verificar integridad de archivos
    mostrar_info "Verificando integridad de archivos..."
    if [ -f "$DIRECTORIO_INSTALACION/occ" ]; then
        chmod +x "$DIRECTORIO_INSTALACION/occ"
        # Aquí se podría ejecutar el comando 'occ integrity:check-core' si PHP está disponible
    fi
}

# Función para mostrar instrucciones post-instalación
mostrar_instrucciones() {
    echo ""
    echo "=============================================================="
    echo "             INSTALACIÓN DE NEXTCLOUD COMPLETADA              "
    echo "=============================================================="
    echo ""
    mostrar_info "Nextcloud se ha descargado correctamente en el directorio '$DIRECTORIO_INSTALACION'."
    echo ""
    mostrar_info "Para completar la configuración, siga estos pasos:"
    echo ""
    echo "1. Mueva el directorio $DIRECTORIO_INSTALACION a la raíz de su servidor web."
    echo "   Por ejemplo: mv $DIRECTORIO_INSTALACION /var/www/html/"
    echo ""
    echo "2. Asegúrese de que su servidor web (Apache/Nginx) esté en funcionamiento."
    echo ""
    echo "3. Configure su base de datos (MySQL/MariaDB, PostgreSQL o SQLite)."
    echo ""
    echo "4. Acceda a Nextcloud desde su navegador web:"
    echo "   http://su-servidor/nextcloud"
    echo ""
    echo "5. Complete el asistente de instalación en el navegador."
    echo ""
    mostrar_advertencia "Requisitos importantes del sistema:"
    echo "- PHP 7.4 o superior con extensiones requeridas"
    echo "- Base de datos MySQL/MariaDB, PostgreSQL o SQLite"
    echo "- Al menos 512MB de RAM recomendado"
    echo "- Permisos de escritura en el directorio de Nextcloud"
    echo ""
    mostrar_info "Para más información, visite:"
    echo "- Documentación oficial: https://docs.nextcloud.com/"
    echo "- Repositorio GitHub: $REPO_GITHUB"
    echo ""
    echo "=============================================================="
}

# Función principal
main() {
    clear
    echo "=============================================================="
    echo "                 INSTALADOR DE NEXTCLOUD                      "
    echo "=============================================================="
    echo "         Desde el repositorio: $REPO_GITHUB                  "
    echo "=============================================================="
    echo ""
    
    # Preguntar si desea personalizar la instalación
    read -p "¿Desea personalizar la instalación? (s/n) [n]: " personalizar
    if [[ "$personalizar" == "s" || "$personalizar" == "S" ]]; then
        read -p "Directorio de instalación [$DIRECTORIO_INSTALACION]: " dir_input
        if [ ! -z "$dir_input" ]; then
            DIRECTORIO_INSTALACION="$dir_input"
        fi
        
        read -p "Idioma predeterminado [$IDIOMA]: " idioma_input
        if [ ! -z "$idioma_input" ]; then
            IDIOMA="$idioma_input"
        fi
        
        read -p "Versión específica (deje en blanco para latest): " version_input
        if [ ! -z "$version_input" ]; then
            VERSION_TAG="$version_input"
        fi
    fi
    
    # Ejecutar los pasos de instalación
    verificar_dependencias
    descargar_nextcloud
    configurar_nextcloud
    mostrar_instrucciones
    
    mostrar_info "Instalación completada. ¡Disfrute de Nextcloud!"
}

# Ejecutar la función principal
main
