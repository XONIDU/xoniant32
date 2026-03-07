# XONIANT32 v4.2.0
### by Darian Alberto Camacho Salas

---

## 📋 Descripción

**XONIANT32** es una transformación ultra minimalista de **antiX Linux** (Debian Stable de 32 bits) que elimina todo lo innecesario y deja solo lo esencial para ejecutar herramientas XONI y tener un entorno gráfico liviano pero funcional.

El script `install-xoniant32.sh` realiza una purga masiva de paquetes y configura el sistema para que quede únicamente con:

- **Openbox** como gestor de ventanas (mínimo)
- **Terminal fija** (rxvt-unicode) maximizada y sin bordes (no se puede cerrar)
- **ALSA** para audio
- **Connman** para WiFi (nativo de antiX)
- **Scripts XONI**: `xoni-install`, `xoni-update`, `xoni-help`, `xoni-menu`
- **Nada más**: sin escritorios, sin barras, sin fondos, sin gestores de display.

---

## ⚠️ Advertencia

Este script está diseñado para **fines educativos y personales**. Realiza una purga masiva de paquetes en tu sistema antiX instalado. **Asegúrate de tener una copia de seguridad de tus datos importantes antes de ejecutarlo**. El autor no se responsabiliza del uso que se le dé.

---

## 📥 Requisitos previos

- Tener **antiX Linux 32 bits ya instalado** en tu disco duro.
- Conexión a internet (cable o WiFi).
- Ejecutar el script con permisos de superusuario (`sudo`).

---

## 🚀 Instalación (desde antiX ya instalado)

Puedes descargar el script de purga usando cualquiera de estos métodos:

### Opción 1: con `wget`

```bash
wget -O install-xoniant32.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install-xoniant32.sh
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

### Opción 2: con `curl`

```bash
curl -L -o install-xoniant32.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install-xoniant32.sh
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

### Opción 3: con `git` (clonando el repositorio)

```bash
git clone https://github.com/XONIDU/xoniant32.git
cd xoniant32
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

El script te guiará interactivamente, pidiendo confirmación antes de comenzar la purga.

---

## 🎯 Primer inicio después de la purga

1. Reinicia el sistema: `sudo reboot`
2. Inicia sesión con tu usuario habitual (la contraseña no cambia).
3. Automáticamente se iniciará el entorno gráfico con una terminal fija (sin bordes, maximizada).

---

## 📦 Comandos XONI disponibles

| Comando | Descripción |
|---------|-------------|
| `xoni-install <herramienta>` | Instala una herramienta XONI desde GitHub (ej: `xoni-install xonitube`). |
| `xoni-update` | Actualiza todo el sistema xoniant32 desde el repositorio GitHub. |
| `xoni-help` | Muestra esta ayuda completa. |
| `xoni-menu` | Abre un menú interactivo con opciones rápidas. |

---

## 🌐 Conectarse a WiFi (connman)

```bash
sudo connmanctl
```

Dentro de `connmanctl`:

```bash
agent on
enable wifi
scan wifi
services
connect wifi_nombre_de_tu_red   # Usa TAB para autocompletar
quit
```

También puedes usar la opción 3 del menú interactivo (`xoni-menu`).

---

## 🔊 Ajustar volumen (ALSA)

```bash
alsamixer
```

Usa las flechas para subir/bajar el volumen y `Esc` para salir.

---

## 📋 Estructura del repositorio

```
xoniant32/
├── install-xoniant32.sh   # Script principal de purga y configuración
├── README.md              # Este archivo
└── .gitignore             # Archivos ignorados
```

---

## 🔄 Actualización del sistema

Para mantener tus scripts XONI actualizados, ejecuta:

```bash
xoni-update
```

Esto clonará/actualizará el repositorio y sincronizará los cambios.

---

## 💻 Hardware soportado

- **Procesador**: 32 bits (i386)
- **RAM**: 512 MB mínimo (recomendado 1 GB)
- **Gráficos**: Cualquier chip compatible con Xorg (controlador fbdev)

---

## ✉️ Contacto y créditos

- **Autor**: Darian Alberto Camacho Salas
- **Email**: xonidu@gmail.com
- **Web**: [https://xonipage.xonidu.com/](https://xonipage.xonidu.com/)
- **GitHub**: [@XONIDU](https://github.com/XONIDU)

---

## 🌐 Enlaces útiles

- [Repositorio XONIANT32](https://github.com/XONIDU/xoniant32)
- [antiX Linux oficial](https://antixlinux.com/)
- [Foro de antiX](https://www.antixforum.com/)

