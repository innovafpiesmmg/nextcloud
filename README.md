# Instalador de Nextcloud para contenedor LXC en Proxmox

Este script está diseñado específicamente para instalar Nextcloud en un contenedor LXC en Proxmox con Ubuntu 20.04 completamente nuevo, sin actualizaciones ni dependencias instaladas. Descarga Nextcloud desde el repositorio de GitHub [innovafpiesmmg/nextcloud](https://github.com/innovafpiesmmg/nextcloud) y configura todo lo necesario para su funcionamiento.

## Características

- 📥 Descarga Nextcloud directamente desde el repositorio en GitHub
- 🔍 Verifica e instala automáticamente las dependencias necesarias en Ubuntu 20.04
- 🌐 Permite personalizar el idioma de la instalación
- 🚀 Incluye indicador de progreso durante la descarga e instalación
- 🔄 Permite seleccionar versiones específicas (tags) del repositorio
- 🛠️ Configura automáticamente los permisos de archivos y directorios
- 📋 Proporciona instrucciones detalladas adaptadas al entorno Proxmox LXC

## Preparación del contenedor LXC en Proxmox

1. Cree un nuevo contenedor LXC en Proxmox con Ubuntu 20.04
2. Configuración recomendada para el contenedor:
   - Al menos 2GB de RAM
   - Al menos 8GB de espacio en disco
   - Acceso a la red con dirección IP fija
   - Privileged container (para algunas funcionalidades avanzadas)

## Instrucciones paso a paso para instalar Nextcloud

### Paso 1: Actualizar el sistema e instalar dependencias básicas

```bash
# Conéctese al contenedor por SSH o consola desde Proxmox
# Luego ejecute estos comandos:

# Actualizar la lista de paquetes
apt update

# Instalar git (necesario para descargar el script)
apt install -y git
```

### Paso 2: Descargar el script de instalación desde GitHub

```bash
# Clonar el repositorio de GitHub
git clone https://github.com/innovafpiesmmg/nextcloud.git

# Entrar al directorio del repositorio
cd nextcloud

# Si solo quiere descargar el script de instalación sin clonar todo el repositorio:
wget -O instalar_nextcloud.sh https://raw.githubusercontent.com/innovafpiesmmg/nextcloud/main/instalar_nextcloud.sh
```

### Paso 3: Ejecutar el script de instalación

```bash
# Dar permisos de ejecución al script
chmod +x instalar_nextcloud.sh

# Ejecutar el script de instalación
./instalar_nextcloud.sh
```

### Paso 4: Seguir las instrucciones interactivas del script

El script le guiará a través de las siguientes opciones:

1. Personalización de la instalación (directorio, idioma, versión)
2. Instalación automática de dependencias necesarias
3. Descarga de Nextcloud desde GitHub
4. Configuración básica de Nextcloud
5. Instalación opcional de Cloudflare Tunnel para acceso seguro

## Opciones de personalización

Durante la ejecución, el script le permitirá personalizar:

- Directorio de instalación (por defecto: `nextcloud`)
- Idioma predeterminado (por defecto: `es`)
- Versión específica a instalar (tag/rama del repositorio)
- Selección del servidor web (Apache o Nginx)
- Configuración básica de la base de datos

## Configuración de red y acceso a través de Cloudflare

Para acceder a Nextcloud de forma segura mediante un túnel de Cloudflare:

1. Asegúrese de que el contenedor tiene acceso a Internet (salida)
2. Configure el túnel de Cloudflare siguiendo estos pasos:
   - Cree una cuenta en Cloudflare (si no tiene una)
   - Configure un dominio en Cloudflare
   - Cree un túnel en la sección "Zero Trust" > "Access" > "Tunnels"
   - Instale el conector Cloudflare en el contenedor LXC
   - Configure el túnel para apuntar al servicio Nextcloud (puerto 80/443)

3. Beneficios de usar un túnel de Cloudflare:
   - Certificado SSL/TLS automático proporcionado por Cloudflare
   - No requiere abrir puertos en el router o firewall
   - Protección contra ataques DDoS
   - Control de acceso adicional (opcional)

## Pasos post-instalación para Cloudflare Tunnel

1. Instalar el conector de Cloudflare en el contenedor LXC:
   ```bash
   # Descargar el binario de cloudflared
   wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   # Instalar el paquete
   dpkg -i cloudflared-linux-amd64.deb
   # Verificar la instalación
   cloudflared --version
   ```

2. Autenticar y crear el túnel:
   ```bash
   # Iniciar sesión en Cloudflare
   cloudflared tunnel login
   # Crear un nuevo túnel
   cloudflared tunnel create nextcloud-tunnel
   # Configurar el túnel (reemplazar UUID con el ID de su túnel)
   cat << EOF > ~/.cloudflared/config.yml
   tunnel: UUID-DE-SU-TUNEL
   credentials-file: /root/.cloudflared/UUID-DE-SU-TUNEL.json
   ingress:
     - hostname: nextcloud.su-dominio.com
       service: http://localhost:80
     - service: http_status:404
   EOF
   ```

3. Configurar el servicio para que se inicie automáticamente:
   ```bash
   cloudflared service install
   ```

3. Optimización para LXC:
   - Ajuste los límites de memoria y CPU en Proxmox según la carga
   - Configure copias de seguridad del contenedor a través de Proxmox

## Solución de problemas específicos en LXC

1. Problemas de permisos:
   - El script configura los permisos adecuados, pero puede necesitar ajustes según la configuración de su contenedor LXC
   - Utilice `lxc-attach` desde el host Proxmox para verificar los logs si el contenedor no es accesible

2. Problemas de red:
   - Verifique que el contenedor tiene acceso a Internet durante la instalación
   - Compruebe que los puertos no están bloqueados por el firewall de Proxmox

3. Limitaciones de recursos:
   - Si Nextcloud funciona lentamente, aumente los recursos asignados al contenedor desde la interfaz de Proxmox

## Créditos

- Nextcloud: [nextcloud.com](https://nextcloud.com)
- Repositorio de instalación: [innovafpiesmmg/nextcloud](https://github.com/innovafpiesmmg/nextcloud)

---

Para más información sobre Nextcloud, visite la [documentación oficial](https://docs.nextcloud.com/).
