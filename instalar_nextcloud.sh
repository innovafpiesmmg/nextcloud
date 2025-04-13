#!/bin/bash

# Script para descargar e instalar Nextcloud desde GitHub en un contenedor LXC con Ubuntu 20.04
# Autor: ChatGPT
# Fecha: 2023
# Versión: 1.2

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
INSTALAR_DEPENDENCIAS="s"  # Por defecto, se instalarán las dependencias faltantes

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

# Función para instalar un paquete si no está instalado
instalar_paquete() {
    local paquete=$1
    if ! dpkg -l | grep -q "^ii  $paquete "; then
        mostrar_info "Instalando $paquete..."
        apt-get update -qq && apt-get install -y $paquete > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            mostrar_advertencia "No se pudo instalar $paquete automáticamente."
            return 1
        else
            mostrar_info "$paquete instalado correctamente."
            return 0
        fi
    else
        mostrar_info "$paquete ya está instalado."
        return 0
    fi
}

# Función para verificar dependencias y opcionalmente instalarlas
verificar_dependencias() {
    mostrar_paso "Verificando dependencias necesarias para Ubuntu 20.04 LXC..."
    
    # Verificar si se ejecuta como root
    if [ "$EUID" -ne 0 ]; then
        mostrar_advertencia "Este script debe ejecutarse como root para instalar dependencias."
        read -p "¿Desea continuar sin privilegios de root? (s/n): " respuesta
        if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
            mostrar_error "Instalación cancelada. Ejecute el script con sudo o como root."
        fi
        INSTALAR_DEPENDENCIAS="n"
    fi
    
    # Verificar si está instalado git
    if ! command -v git &> /dev/null; then
        mostrar_advertencia "Git no está instalado."
        if [ "$INSTALAR_DEPENDENCIAS" = "s" ]; then
            instalar_paquete "git"
            if [ $? -ne 0 ]; then
                mostrar_error "Se requiere Git para clonar el repositorio. Instale Git manualmente con: apt-get install git"
            fi
        else
            mostrar_error "Se requiere Git para clonar el repositorio. Instale Git antes de continuar."
        fi
    else
        mostrar_info "Git está instalado correctamente."
    fi
    
    # Verificar si está instalado curl o wget
    if command -v curl &> /dev/null; then
        DESCARGADOR="curl"
        mostrar_info "Se utilizará curl para las descargas adicionales."
    elif command -v wget &> /dev/null; then
        DESCARGADOR="wget"
        mostrar_info "Se utilizará wget para las descargas adicionales."
    else
        mostrar_advertencia "No se detectó curl o wget."
        if [ "$INSTALAR_DEPENDENCIAS" = "s" ]; then
            instalar_paquete "curl"
            if [ $? -eq 0 ]; then
                DESCARGADOR="curl"
                mostrar_info "Se instaló curl correctamente."
            else
                mostrar_advertencia "No se pudo instalar curl. Intentando instalar wget..."
                instalar_paquete "wget"
                if [ $? -eq 0 ]; then
                    DESCARGADOR="wget"
                    mostrar_info "Se instaló wget correctamente."
                else
                    mostrar_advertencia "No se pudo instalar curl ni wget. Algunas funcionalidades podrían no estar disponibles."
                fi
            fi
        else
            mostrar_advertencia "Se recomienda instalar curl o wget. Algunas funcionalidades podrían no estar disponibles."
        fi
    fi

    # Verificar si unzip está instalado
    if ! command -v unzip &> /dev/null; then
        mostrar_advertencia "No se detectó unzip, que puede ser necesario para descomprimir archivos."
        if [ "$INSTALAR_DEPENDENCIAS" = "s" ]; then
            instalar_paquete "unzip"
            if [ $? -ne 0 ]; then
                read -p "¿Desea continuar sin unzip? (s/n): " respuesta
                if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
                    mostrar_error "Instalación cancelada. Instale unzip manualmente con: apt-get install unzip"
                fi
            fi
        else
            read -p "¿Desea continuar sin unzip? (s/n): " respuesta
            if [[ "$respuesta" != "s" && "$respuesta" != "S" ]]; then
                mostrar_error "Instalación cancelada. Instale unzip antes de continuar."
            fi
        fi
    else
        mostrar_info "Unzip está instalado correctamente."
    fi
    
    # Verificar requisitos para Nextcloud
    mostrar_info "Verificando requisitos para Nextcloud en Ubuntu 20.04..."
    
    # Verificar PHP
    if ! command -v php &> /dev/null; then
        mostrar_advertencia "PHP no está instalado. Nextcloud requiere PHP 7.4 o superior."
        if [ "$INSTALAR_DEPENDENCIAS" = "s" ]; then
            mostrar_info "Instalando PHP y extensiones necesarias para Nextcloud..."
            apt-get update -qq
            apt-get install -y php7.4 php7.4-cli php7.4-common php7.4-fpm php7.4-json php7.4-mbstring php7.4-xml php7.4-zip php7.4-gd php7.4-curl php7.4-mysql php7.4-intl php7.4-bcmath php7.4-gmp > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                mostrar_advertencia "No se pudieron instalar automáticamente todas las extensiones de PHP necesarias."
                mostrar_advertencia "Es posible que necesite instalarlas manualmente más tarde."
            else
                PHP_VERSION=$(php -r 'echo PHP_VERSION;')
                mostrar_info "PHP versión $PHP_VERSION instalado correctamente con las extensiones necesarias."
            fi
        else
            mostrar_advertencia "Nextcloud requiere PHP 7.4 o superior con varias extensiones. Se recomienda instalarlo antes de continuar."
        fi
    else
        PHP_VERSION=$(php -r 'echo PHP_VERSION;')
        mostrar_info "PHP versión $PHP_VERSION está instalado."
        
        # Verificar versión de PHP (se recomienda 7.4 o superior)
        if [[ "$(php -r 'echo version_compare(PHP_VERSION, "7.4.0", ">=") ? "1" : "0";')" == "0" ]]; then
            mostrar_advertencia "Se recomienda PHP 7.4 o superior para Nextcloud."
            if [ "$INSTALAR_DEPENDENCIAS" = "s" ]; then
                mostrar_info "Intentando actualizar PHP a 7.4..."
                apt-get update -qq
                apt-get install -y php7.4 php7.4-cli php7.4-common php7.4-fpm php7.4-json php7.4-mbstring php7.4-xml php7.4-zip php7.4-gd php7.4-curl php7.4-mysql php7.4-intl php7.4-bcmath php7.4-gmp > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    PHP_VERSION=$(php -r 'echo PHP_VERSION;')
                    mostrar_info "PHP actualizado a versión $PHP_VERSION."
                else
                    mostrar_advertencia "No se pudo actualizar PHP a la versión 7.4."
                fi
            fi
        fi
        
        # Verificar extensiones de PHP necesarias
        mostrar_info "Verificando extensiones de PHP necesarias..."
        EXTENSIONES_FALTANTES=""
        for ext in ctype curl dom gd iconv json mbstring posix simplexml xml xmlwriter zip zlib; do
            if ! php -m | grep -i -q $ext; then
                EXTENSIONES_FALTANTES="$EXTENSIONES_FALTANTES $ext"
            fi
        done
        
        if [ ! -z "$EXTENSIONES_FALTANTES" ]; then
            mostrar_advertencia "Faltan las siguientes extensiones de PHP:$EXTENSIONES_FALTANTES"
            if [ "$INSTALAR_DEPENDENCIAS" = "s" ]; then
                mostrar_info "Intentando instalar extensiones de PHP faltantes..."
                apt-get update -qq
                apt-get install -y php7.4-common php7.4-json php7.4-mbstring php7.4-xml php7.4-zip php7.4-gd php7.4-curl php7.4-intl php7.4-bcmath php7.4-gmp > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    mostrar_info "Extensiones de PHP instaladas correctamente."
                else
                    mostrar_advertencia "No se pudieron instalar todas las extensiones de PHP automáticamente."
                fi
            else
                mostrar_advertencia "Se recomienda instalar las extensiones de PHP faltantes para el correcto funcionamiento de Nextcloud."
            fi
        fi
    fi
    
    # Verificar servidor web
    if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
        mostrar_info "Se detectó Apache instalado."
        SERVIDOR_WEB="apache"
    elif command -v nginx &> /dev/null; then
        mostrar_info "Se detectó Nginx instalado."
        SERVIDOR_WEB="nginx"
    else
        mostrar_advertencia "No se detectó ningún servidor web (Apache/Nginx). Nextcloud requiere un servidor web."
        if [ "$INSTALAR_DEPENDENCIAS" = "s" ]; then
            echo "¿Qué servidor web desea instalar?"
            echo "1) Apache (recomendado para instalación sencilla)"
            echo "2) Nginx (mejor rendimiento pero configuración más compleja)"
            echo "3) Ninguno (instalaré manualmente)"
            read -p "Elija una opción (1-3): " opcion_web
            
            case $opcion_web in
                1)
                    mostrar_info "Instalando Apache..."
                    apt-get update -qq && apt-get install -y apache2 libapache2-mod-php7.4 > /dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        mostrar_info "Apache instalado correctamente."
                        SERVIDOR_WEB="apache"
                        # Habilitar módulos necesarios
                        a2enmod rewrite headers env dir mime ssl > /dev/null 2>&1
                    else
                        mostrar_advertencia "No se pudo instalar Apache."
                    fi
                    ;;
                2)
                    mostrar_info "Instalando Nginx..."
                    apt-get update -qq && apt-get install -y nginx php7.4-fpm > /dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        mostrar_info "Nginx instalado correctamente."
                        SERVIDOR_WEB="nginx"
                    else
                        mostrar_advertencia "No se pudo instalar Nginx."
                    fi
                    ;;
                *)
                    mostrar_advertencia "No se instalará ningún servidor web. Deberá configurarlo manualmente."
                    ;;
            esac
        else
            mostrar_advertencia "Se recomienda instalar Apache o Nginx antes de continuar."
        fi
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
    mostrar_info "Para completar la configuración en el contenedor LXC, siga estos pasos:"
    echo ""
    echo "1. Mueva el directorio $DIRECTORIO_INSTALACION a la raíz de su servidor web."
    echo "   Por ejemplo: mv $DIRECTORIO_INSTALACION /var/www/html/"
    echo ""
    echo "2. Asegúrese de que su servidor web (Apache/Nginx) esté en funcionamiento."
    echo ""
    echo "3. Configure su base de datos (MySQL/MariaDB, PostgreSQL o SQLite)."
    echo ""
    echo "4. Para acceder de forma segura mediante Cloudflare Tunnel:"
    echo ""
    mostrar_paso "Configuración del túnel de Cloudflare:"
    echo ""
    echo "   a) Instale el conector Cloudflare:"
    echo "      wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    echo "      dpkg -i cloudflared-linux-amd64.deb"
    echo ""
    echo "   b) Inicie sesión en Cloudflare:"
    echo "      cloudflared tunnel login"
    echo ""
    echo "   c) Cree un túnel:"
    echo "      cloudflared tunnel create nextcloud-tunnel"
    echo ""
    echo "   d) Configure el túnel (reemplace UUID con el ID de su túnel):"
    echo "      cat << EOF > ~/.cloudflared/config.yml"
    echo "      tunnel: UUID-DE-SU-TUNEL"
    echo "      credentials-file: /root/.cloudflared/UUID-DE-SU-TUNEL.json"
    echo "      ingress:"
    echo "        - hostname: nextcloud.su-dominio.com"
    echo "          service: http://localhost:80"
    echo "        - service: http_status:404"
    echo "      EOF"
    echo ""
    echo "   e) Configure el registro DNS en el panel de Cloudflare:"
    echo "      cloudflared tunnel route dns nextcloud-tunnel nextcloud.su-dominio.com"
    echo ""
    echo "   f) Inicie el servicio:"
    echo "      cloudflared service install"
    echo "      systemctl start cloudflared"
    echo "      systemctl enable cloudflared"
    echo ""
    echo "5. Acceda a Nextcloud a través de su dominio configurado en Cloudflare:"
    echo "   https://nextcloud.su-dominio.com"
    echo ""
    echo "6. Complete el asistente de instalación en el navegador."
    echo ""
    mostrar_advertencia "Requisitos importantes del sistema:"
    echo "- PHP 7.4 o superior con extensiones requeridas"
    echo "- Base de datos MySQL/MariaDB, PostgreSQL o SQLite"
    echo "- Al menos 2GB de RAM recomendado para el contenedor LXC"
    echo "- Al menos 10GB de espacio en disco"
    echo "- Permisos de escritura en el directorio de Nextcloud"
    echo ""
    mostrar_info "Beneficios de usar Cloudflare Tunnel:"
    echo "- Certificado SSL/TLS automático"
    echo "- No requiere abrir puertos en el router o firewall"
    echo "- Protección contra ataques DDoS"
    echo "- Mayor seguridad para su instancia de Nextcloud"
    echo ""
    mostrar_info "Para más información, visite:"
    echo "- Documentación de Nextcloud: https://docs.nextcloud.com/"
    echo "- Documentación de Cloudflare Tunnel: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/"
    echo "- Repositorio GitHub: $REPO_GITHUB"
    echo ""
    echo "=============================================================="
}

# Función para instalar Cloudflare Tunnel
instalar_cloudflare_tunnel() {
    mostrar_paso "Instalando Cloudflare Tunnel (opcional)..."
    
    # Preguntar si desea instalar Cloudflare Tunnel
    read -p "¿Desea instalar y configurar Cloudflare Tunnel? (s/n) [n]: " instalar_tunnel
    if [[ "$instalar_tunnel" != "s" && "$instalar_tunnel" != "S" ]]; then
        mostrar_info "Omitiendo instalación de Cloudflare Tunnel. Puede instalarlo manualmente más tarde."
        return
    fi
    
    # Verificar si cloudflared ya está instalado
    if command -v cloudflared &> /dev/null; then
        mostrar_info "Cloudflare Tunnel ya está instalado."
        CLOUDFLARED_VERSION=$(cloudflared --version | head -n 1)
        mostrar_info "Versión: $CLOUDFLARED_VERSION"
    else
        mostrar_info "Descargando Cloudflare Tunnel..."
        
        # Descargar cloudflared
        if [ "$DESCARGADOR" = "curl" ]; then
            curl -L -o cloudflared-linux-amd64.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb || mostrar_error "Falló la descarga con curl."
        else
            wget -q -O cloudflared-linux-amd64.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb || mostrar_error "Falló la descarga con wget."
        fi
        
        # Instalar cloudflared
        if [ "$INSTALAR_DEPENDENCIAS" = "s" ]; then
            mostrar_info "Instalando Cloudflare Tunnel..."
            dpkg -i cloudflared-linux-amd64.deb &> /dev/null
            if [ $? -ne 0 ]; then
                mostrar_advertencia "Error al instalar Cloudflare Tunnel. Intente instalarlo manualmente."
                return
            fi
            mostrar_info "Cloudflare Tunnel instalado correctamente."
            rm cloudflared-linux-amd64.deb
        else
            mostrar_info "El paquete cloudflared-linux-amd64.deb se ha descargado. Instálelo manualmente con:"
            echo "dpkg -i cloudflared-linux-amd64.deb"
            return
        fi
    fi
    
    # Configurar Cloudflare Tunnel
    mostrar_info "Para completar la configuración de Cloudflare Tunnel, siga estos pasos:"
    echo ""
    echo "1. Ejecute el siguiente comando para iniciar sesión en su cuenta de Cloudflare:"
    echo "   cloudflared tunnel login"
    echo ""
    echo "2. Cree un nuevo túnel:"
    echo "   cloudflared tunnel create nextcloud-tunnel"
    echo ""
    echo "3. Configure el túnel (reemplace UUID con el ID de su túnel):"
    echo "   mkdir -p ~/.cloudflared"
    echo "   nano ~/.cloudflared/config.yml"
    echo ""
    echo "   Y añada el siguiente contenido:"
    echo "   tunnel: UUID-DE-SU-TUNEL"
    echo "   credentials-file: /root/.cloudflared/UUID-DE-SU-TUNEL.json"
    echo "   ingress:"
    echo "     - hostname: nextcloud.su-dominio.com"
    echo "       service: http://localhost:80"
    echo "     - service: http_status:404"
    echo ""
    echo "4. Configure el registro DNS en el panel de Cloudflare:"
    echo "   cloudflared tunnel route dns nextcloud-tunnel nextcloud.su-dominio.com"
    echo ""
    echo "5. Instale y active el servicio:"
    echo "   cloudflared service install"
    echo "   systemctl start cloudflared"
    echo "   systemctl enable cloudflared"
    echo ""
    
    mostrar_info "Una vez configurado, podrá acceder a Nextcloud a través de https://nextcloud.su-dominio.com"
}

# Función principal
main() {
    clear
    echo "=============================================================="
    echo "                 INSTALADOR DE NEXTCLOUD                      "
    echo "=============================================================="
    echo "         Desde el repositorio: $REPO_GITHUB                  "
    echo "         Para contenedor LXC en Proxmox con Ubuntu 20.04     "
    echo "=============================================================="
    echo ""
    
    # Verificar si estamos en Ubuntu 20.04
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" = "20.04" ]; then
            mostrar_info "Detectado: Ubuntu 20.04 LTS"
        else
            mostrar_advertencia "Este script está optimizado para Ubuntu 20.04 LTS. Detectado: $PRETTY_NAME"
            read -p "¿Desea continuar de todos modos? (s/n) [n]: " continuar
            if [[ "$continuar" != "s" && "$continuar" != "S" ]]; then
                mostrar_error "Instalación cancelada."
            fi
        fi
    fi
    
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
        
        read -p "¿Instalar dependencias automáticamente? (s/n) [$INSTALAR_DEPENDENCIAS]: " deps_input
        if [ ! -z "$deps_input" ]; then
            INSTALAR_DEPENDENCIAS="$deps_input"
        fi
    fi
    
    # Ejecutar los pasos de instalación
    verificar_dependencias
    descargar_nextcloud
    configurar_nextcloud
    instalar_cloudflare_tunnel
    mostrar_instrucciones
    
    mostrar_info "Instalación completada. ¡Disfrute de Nextcloud con Cloudflare Tunnel!"
}

# Ejecutar la función principal
main
