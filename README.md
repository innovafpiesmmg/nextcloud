# Instalador de Nextcloud desde GitHub

Este script permite descargar e instalar Nextcloud directamente desde el repositorio de GitHub [innovafpiesmmg/nextcloud](https://github.com/innovafpiesmmg/nextcloud). La herramienta está diseñada para facilitar la instalación de Nextcloud en servidores web, verificando los requisitos necesarios y proporcionando una guía paso a paso.

## Características

- 📥 Descarga Nextcloud directamente desde el repositorio oficial en GitHub
- 🔍 Verifica automáticamente los requisitos del sistema y dependencias
- 🌐 Permite personalizar el idioma de la instalación
- 🚀 Incluye indicador de progreso durante la descarga
- 🔄 Permite seleccionar versiones específicas (tags) del repositorio
- 🛠️ Configura automáticamente los permisos de archivos y directorios
- 📋 Proporciona instrucciones detalladas post-instalación

## Requisitos previos

Para utilizar este script, necesitará:

- Sistema operativo Linux/Unix
- Git instalado
- Acceso a Internet para descargar desde GitHub
- Permisos para ejecutar scripts bash

## Instalación

1. Descargue el script `instalar_nextcloud.sh`
2. Otorgue permisos de ejecución:
   ```bash
   chmod +x instalar_nextcloud.sh
   ```
3. Ejecute el script:
   ```bash
   ./instalar_nextcloud.sh
   ```

## Opciones de personalización

Durante la ejecución, el script le permitirá personalizar:

- Directorio de instalación (por defecto: `nextcloud`)
- Idioma predeterminado (por defecto: `es`)
- Versión específica a instalar (tag/rama del repositorio)

## Requisitos del sistema para Nextcloud

- PHP 7.4 o superior con las siguientes extensiones:
  - ctype
  - curl
  - dom
  - GD
  - JSON
  - mbstring
  - posix
  - SimpleXML
  - XMLWriter
  - zip
  - zlib
  
- Servidor web (Apache/Nginx)
- Base de datos (MySQL/MariaDB, PostgreSQL o SQLite)
- Al menos 512MB de RAM recomendado

## Instrucciones post-instalación

Después de ejecutar el script, deberá:

1. Mover el directorio de instalación a la raíz de su servidor web
2. Configurar su servidor web para servir Nextcloud
3. Configurar una base de datos para Nextcloud
4. Acceder al instalador web de Nextcloud a través de su navegador
5. Completar la configuración siguiendo las instrucciones en pantalla

## Solución de problemas

Si encuentra algún problema durante la instalación:

1. Verifique que todos los requisitos previos estén instalados
2. Asegúrese de tener una conexión a Internet estable
3. Compruebe que tiene permisos suficientes en el directorio de destino
4. Revise los logs de error del servidor web después de la instalación

## Contribuir

Si desea contribuir a este script, puede:

1. Crear un fork del repositorio
2. Realizar sus cambios
3. Enviar un pull request

## Licencia

Este script se distribuye bajo la licencia MIT. Consulte el archivo LICENSE para más detalles.

## Créditos

- Nextcloud: [nextcloud.com](https://nextcloud.com)
- Repositorio de instalación: [innovafpiesmmg/nextcloud](https://github.com/innovafpiesmmg/nextcloud)

---

Para más información sobre Nextcloud, visite la [documentación oficial](https://docs.nextcloud.com/).