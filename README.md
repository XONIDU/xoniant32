# XONIANT32 v1.32.1

### by Darian Alberto Camacho Salas

---

## Descripción

**XONIANT32** es una distribución Linux especializada que transforma antiX Linux en un entorno de terminal gráfica fija, diseñada específicamente para hardware de 32 bits con recursos limitados, como la ASUS Eee PC 900. Su propósito es proporcionar una base ultra ligera pero completamente funcional para ejecutar herramientas XONI (xonitube, xonigraf, xonichat, xonimail) sin perder compatibilidad con controladores gráficos, de audio y multimedia.

Este proyecto forma parte del ecosistema **XONIDU**, una organización dedicada al desarrollo de código abierto con énfasis en automatización, optimización de procesos y democratización del acceso a herramientas tecnológicas eficientes.

**Versión actual:** 1.32.1 (Primera versión estable y funcional)

---

## Características

- Terminal principal fija que ocupa toda la pantalla, sin bordes, sin botón de cerrar.
- Ventanas emergentes (mpv, nuevas terminales) se ven ENCIMA de la terminal principal.
- Soporte completo de ratón: seleccionar texto copia, click derecho pega.
- Atajos de teclado completos: Alt+Tab, Alt+F4, Alt+F10, Win+↑, Ctrl+Alt+T, Win+x, Win+q.
- Actualización desde GitHub: `xoni-update` mantiene tu sistema al día.
- Instalación modular: `xoni-install` descarga herramientas XONI bajo demanda.
- Optimización de recursos: elimina paquetes innecesarios pero conserva todos los controladores gráficos y multimedia.

---

## Requisitos

- Procesador de 32 bits (i386)
- 512 MB de RAM (recomendado 1 GB)
- 8 GB de espacio en disco
- antiX Linux 23.2 (32 bits) instalado o live USB

---

## Descarga de la ISO base

Puedes descargar la ISO base de antiX-23.2 (32 bits) desde el siguiente enlace:

[https://sourceforge.net/projects/antix-linux/files/Final/antiX-23.2/antiX-23.2_386-full.iso/download](https://sourceforge.net/projects/antix-linux/files/Final/antiX-23.2/antiX-23.2_386-full.iso/download)

También puedes usar los mirrors oficiales de antiX para obtener la ISO.

---

## Instalación

### Opción 1: con wget

```bash
wget -O install-xoniant32.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install-xoniant32.sh
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

### Opción 2: con curl

```bash
curl -L -o install-xoniant32.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install-xoniant32.sh
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

### Opción 3: con git (clonando el repositorio)

```bash
git clone https://github.com/XONIDU/xoniant32.git
cd xoniant32
chmod +x install-xoniant32.sh
sudo ./install-xoniant32.sh
```

El script te pedirá confirmación una vez y luego hará todo automáticamente.

---

## Primer inicio después de la instalación

1. Reinicia el sistema: `sudo reboot`
2. Inicia sesión con tu usuario habitual (`demo`/`demo` si es la primera vez)
3. El sistema arrancará directamente en una terminal negra ocupando toda la pantalla
4. La terminal principal **NO SE PUEDE CERRAR**

---

## Comandos XONI

| Comando | Descripción |
|---------|-------------|
| `xoni-install <herramienta>` | Instala una herramienta XONI desde GitHub |
| `xoni-update` | Actualiza xoniant32 desde GitHub |
| `xoni-menu` | Abre menú interactivo |
| `xoni-help` | Muestra ayuda completa |

### Herramientas disponibles

```bash
xoni-install xonitube    # Buscador y reproductor de YouTube
xoni-install xonigraf    # Graficador matemático
xoni-install xonichat    # Chat con IA (Gemini)
xoni-install xonimail    # Cliente de correo
```

---

## Atajos de teclado

| Tecla | Acción |
|-------|--------|
| `Alt+Tab` | Cambiar entre ventanas emergentes |
| `Alt+F4` | Cerrar ventana actual (excepto la principal) |
| `Alt+F10` | Maximizar/restaurar ventana |
| `Win+↑` | Maximizar ventana |
| `Ctrl+Alt+T` | Abrir nueva terminal (emergente) |
| `Win+x` | Abrir menú principal |
| `Win+q` | Cerrar sesión |

---

## Ratón y portapapeles

- Seleccionar texto con el botón izquierdo → copia automáticamente
- Click derecho → pega el texto copiado
- `Ctrl+Shift+C` / `Ctrl+Insert` → copiar
- `Ctrl+Shift+V` / `Shift+Insert` → pegar

---

## Conectarse a WiFi

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

---

## Ajustar volumen

```bash
alsamixer
```

Usa flechas para subir/bajar volumen, `Esc` para salir.

---

## Actualización del sistema

```bash
sudo xoni-update
```

Esto clona/actualiza el repositorio desde GitHub y sincroniza los cambios en `/usr/local/bin/`.

---

## Hardware soportado

**Mínimo:**
- Procesador: 32 bits (i386)
- RAM: 512 MB
- Almacenamiento: 8 GB
- Gráficos: Cualquier chip compatible con Xorg

**Probado en:**
- ASUS Eee PC 900 (Intel Celeron M 900MHz, 1GB RAM, GMA 900)
- ThinkPad X60 (Intel Core Duo, 32 bits)
- VirtualBox / QEMU

---

## Solución de problemas

### El escritorio sigue apareciendo

Verificar que Openbox está configurado como sesión por defecto:

```bash
cat /etc/lightdm/lightdm.conf.d/50-xoniant32.conf
```

### No se conecta WiFi

Reiniciar connman:

```bash
sudo sv restart connman   # antiX usa runit
sudo connmanctl
```

### El video de XoniTube no se ve

Verificar backend de mpv:

```bash
mpv --vo=help
mpv --vo=x11 https://youtu.be/...
```

### No aparece el menú con Win+x

Verificar atajos en Openbox:

```bash
grep "W-x" ~/.config/openbox/rc.xml
```

---

## Estructura del repositorio

```
xoniant32/
├── install-xoniant32.sh   # Script de instalación principal (v1.32.1)
├── README.md              # Este archivo
├── requisitos.txt         # Dependencias y requisitos
└── .gitignore             # Archivos ignorados
```

---

## Contacto y créditos

- **Autor:** Darian Alberto Camacho Salas
- **Email:** xonidu@gmail.com
- **Web:** https://xonipage.xonidu.com/
- **GitHub:** [@XONIDU](https://github.com/XONIDU)
- **Organización:** XONIDU

---

## Enlaces útiles

- Repositorio XONIANT32: [https://github.com/XONIDU/xoniant32](https://github.com/XONIDU/xoniant32)
- Documentación en Calaméo: [https://www.calameo.com/read/00817762416445fe17e96](https://www.calameo.com/read/00817762416445fe17e96)
- antiX Linux oficial: [https://antixlinux.com/](https://antixlinux.com/)
- Foro de antiX: [https://www.antixforum.com/](https://www.antixforum.com/)

## Cualquier duda o comentario, contactanos
