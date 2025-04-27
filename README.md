# Instalación y Configuración de Nextcloud All-in-One (AIO) con Collabora Online en Ubuntu (Proxmox LXC)

Esta guía describe los pasos para instalar Nextcloud All-in-One (AIO) en un contenedor LXC de Ubuntu dentro de Proxmox y habilitar Collabora Online a través de la interfaz de AIO.

**Importante:** Nextcloud AIO gestiona sus propios contenedores Docker, incluyendo el de Collabora Online. **No instales Collabora Online por separado.** Utiliza la opción integrada en AIO.

## 1. Prerrequisitos

* **Servidor Proxmox VE:** Con un contenedor LXC de Ubuntu (recomendado 22.04 LTS o superior) ya creado.
* **Contenedor LXC:**
    * **Recursos:** Mínimo 2 CPU cores, 4GB RAM (recomendado 8GB+ para mejor rendimiento con Collabora), y suficiente espacio en disco para tus datos.
    * **Red:** Configuración de red funcional (IP estática recomendada).
    * **Acceso Root/Sudo:** Necesitarás acceso `root` o un usuario con `sudo` dentro del contenedor.
    * **Docker:** El script instalará Docker si no está presente. Asegúrate de que la virtualización anidada (nesting) y el montaje de keyctl estén habilitados en las opciones del contenedor LXC en Proxmox para que Docker funcione correctamente:
        * Ve a `Tu Contenedor -> Options -> Features`.
        * Habilita `nesting=1` y `keyctl=1`.
* **Nombre de Dominio (Recomendado):** Un nombre de dominio o subdominio que apunte a la dirección IP pública de tu servidor (o la IP del contenedor si está expuesto directamente o a través de un proxy). AIO gestionará los certificados SSL/TLS automáticamente si usas un dominio.
* **Puertos Abiertos:** Asegúrate de que los siguientes puertos estén abiertos en tu firewall y redirigidos correctamente a la IP del contenedor LXC si estás detrás de un NAT:
    * **TCP 80:** Para la validación inicial de certificados Let's Encrypt.
    * **TCP 443:** Para el acceso HTTPS a Nextcloud (gestionado por AIO o tu proxy inverso).
    * **TCP 8080:** Para acceder a la interfaz de gestión de AIO inicialmente.
    * **TCP 8443:** Puerto alternativo para la interfaz de gestión AIO (especialmente útil si usas un proxy inverso).

## 2. Instalación

1.  **Accede al Contenedor:** Conéctate a tu contenedor LXC de Ubuntu mediante SSH o la consola de Proxmox.
    ```bash
    ssh tu_usuario@<IP_DEL_CONTENEDOR>
    # o usa la consola de Proxmox
    ```
2.  **Descarga el Script:** Descarga el script `install_nextcloud_aio.sh` proporcionado o cópialo en un archivo dentro del contenedor.
    ```bash
    # Ejemplo usando curl (si tienes el script en una URL)
    # curl -O URL_DEL_SCRIPT/install_nextcloud_aio.sh

    # O créalo manualmente:
    nano install_nextcloud_aio.sh
    # Pega el contenido del script aquí
    # Guarda y cierra (Ctrl+X, luego Y, luego Enter)
    ```
3.  **Hazlo Ejecutable:**
    ```bash
    chmod +x install_nextcloud_aio.sh
    ```
4.  **Ejecuta el Script:** Ejecútalo con `sudo`.
    ```bash
    sudo ./install_nextcloud_aio.sh
    ```
    El script actualizará el sistema, instalará Docker si es necesario, y descargará e iniciará el contenedor maestro de Nextcloud AIO.

## 3. Configuración Inicial de Nextcloud AIO

1.  **Accede a la Interfaz AIO:** Abre tu navegador web y ve a `https://<IP_DEL_CONTENEDOR>:8080`.
    * **Advertencia de Seguridad:** Es probable que veas una advertencia de seguridad del navegador porque AIO usa un certificado autofirmado inicialmente. Acepta el riesgo y continúa.
2.  **Obtén la Contraseña:** El script de inicio de AIO (en la terminal donde lo ejecutaste) te mostrará una contraseña inicial. Cópiala. Si cerraste la terminal, puedes obtenerla con:
    ```bash
    sudo docker logs nextcloud-aio-mastercontainer
    ```
3.  **Inicia Sesión:** Pega la contraseña en la interfaz web de AIO.
4.  **Configuración del Dominio:** Introduce el nombre de dominio que has configurado para tu Nextcloud (ej. `cloud.tudominio.com`). AIO usará esto para obtener certificados SSL/TLS válidos de Let's Encrypt. Si no tienes un dominio, puedes usar la IP, pero no tendrás HTTPS seguro de forma automática.
5.  **Selección de Componentes (¡Importante!):**
    * La interfaz de AIO te permitirá seleccionar componentes adicionales.
    * **Marca la casilla correspondiente a "Collabora Online"** (puede llamarse "Built-in CODE Server" o similar).
    * Puedes seleccionar otros componentes que necesites (ej. Talk, Calendar, etc.).
6.  **Inicia la Descarga e Instalación:** Haz clic en "Download and start containers". AIO comenzará a descargar y configurar todos los contenedores necesarios (Nextcloud, Base de Datos, Collabora, etc.). Este proceso puede tardar bastante tiempo dependiendo de tu conexión a internet y los recursos del servidor.
7.  **Crea tu Cuenta de Administrador:** Una vez que todos los contenedores estén listos, la interfaz de AIO te proporcionará un enlace para acceder a tu instancia de Nextcloud recién instalada y te dará una contraseña de administrador generada aleatoriamente.
    * Accede a tu Nextcloud (`https://tu.dominio.com` o la IP).
    * Inicia sesión con el usuario `admin` y la contraseña proporcionada.
    * **¡Cambia la contraseña de administrador inmediatamente!**

## 4. Verificación de Collabora Online

1.  Dentro de Nextcloud, ve a `Archivos`.
2.  Haz clic en el botón `+` (Nuevo) y selecciona `Nuevo Documento`, `Nueva Hoja de Cálculo` o `Nueva Presentación`.
3.  Debería abrirse la interfaz de edición de Collabora Online dentro de Nextcloud. Si funciona, ¡la integración está completa!

## 5. Actualización de Nextcloud AIO

Nextcloud AIO simplifica las actualizaciones:

1.  **Accede a la Interfaz AIO:** Ve a `https://<IP_O_DOMINIO>:8080` (o `:8443` si usas proxy).
2.  **Inicia Sesión:** Usa la contraseña de AIO (la que obtuviste inicialmente o la que hayas cambiado).
3.  **Busca Actualizaciones:** La interfaz de AIO te notificará si hay actualizaciones disponibles para el contenedor maestro o para los contenedores de Nextcloud y sus componentes.
4.  **Aplica las Actualizaciones:** Sigue las instrucciones en pantalla para actualizar los contenedores. AIO se encargará de detener, actualizar e iniciar los contenedores necesarios.

## 6. Configuración Adicional (Opcional)

* **Proxy Inverso:** Si quieres acceder a Nextcloud a través del puerto estándar 443 y gestionar SSL/TLS externamente (ej. con Nginx Proxy Manager, Traefik, Caddy), puedes configurar un proxy inverso. Consulta la documentación oficial de Nextcloud AIO para obtener guías específicas sobre cómo hacerlo. AIO tiene soporte integrado para esto.
* **Copias de Seguridad:** AIO incluye una función de copia de seguridad integrada. Configúrala desde la interfaz de AIO para realizar backups regulares de tus datos, configuración y base de datos. ¡Es crucial!
* **Ajustes del Contenedor LXC:** Monitoriza el uso de CPU, RAM y disco del contenedor LXC en Proxmox y ajusta los recursos asignados si es necesario.

## 7. Solución de Problemas

* **Error de Docker en LXC:** Asegúrate de que `nesting=1` y `keyctl=1` estén habilitados en las opciones del contenedor en Proxmox. Reinicia el contenedor después de cambiar estas opciones.
* **Problemas de Acceso a la Interfaz AIO:** Verifica que los puertos (8080, 8443) estén abiertos y no bloqueados por un firewall (en el host Proxmox o en el propio contenedor `ufw`).
* **Error al Obtener Certificado SSL:** Asegúrate de que tu dominio apunta correctamente a la IP pública del servidor y que el puerto 80 está abierto y accesible desde internet para la validación Let's Encrypt.
* **Consulta los Logs:** Si algo falla, revisa los logs del contenedor maestro de AIO:
    ```bash
    sudo docker logs nextcloud-aio-mastercontainer
    ```
    Y los logs de los otros contenedores gestionados por AIO (puedes verlos con `sudo docker ps -a` y luego `sudo docker logs <nombre_contenedor>`).
* **Documentación Oficial:** Consulta la [documentación oficial de Nextcloud AIO](https://github.com/nextcloud/all-in-one#readme) para obtener información más detallada y soluciones a problemas comunes.


