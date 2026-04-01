# XONIANT32 ULTIMATE
### by Darian Alberto Camacho Salas

---

## 📋 Descripción

**XONIANT32 ULTIMATE** es una transformación optimizada de **antiX Linux** (Debian Stable de 32 bits) que convierte tu sistema en una **terminal gráfica fija**, eliminando todo lo innecesario pero conservando TODOS los controladores gráficos, de audio y multimedia. Ideal para hardware antiguo (como ASUS Eee PC 900) con máxima compatibilidad para reproducción de video y herramientas XONI.

---

## 📦 Contenido del repositorio

```
xoniant32/
├── antiX-386.iso                    # ISO base de antiX 32 bits
├── install-xoniant32-ultimate.sh   # Script de instalación principal
├── README.md                        # Este archivo
└── .gitignore                        # Archivos ignorados
```

---

## 🚀 Opciones de instalación

### Opción 1: Usar la ISO base antiX + script (recomendado)

1. **Descarga el repositorio**:
   ```bash
   git clone https://github.com/XONIDU/xoniant32.git
   cd xoniant32
   ```

2. **Graba la ISO antiX en un USB**:
   ```bash
   sudo dd if=antiX-386.iso of=/dev/sdX bs=4M status=progress
   ```
   *(Reemplaza `/dev/sdX` con tu dispositivo USB)*

3. **Arranca desde el USB** (usuario `demo`, contraseña `demo`)

4. **Conéctate a internet** (WiFi con connman o cable)

5. **Descarga y ejecuta el script**:
   ```bash
   wget -O install-xoniant32-ultimate.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install-xoniant32-ultimate.sh
   chmod +x install-xoniant32-ultimate.sh
   sudo ./install-xoniant32-ultimate.sh
   ```

6. **Reinicia** cuando termine.

### Opción 2: Instalar desde antiX live USB (script manual)

1. **Arranca desde antiX live USB** (usuario `demo`, contraseña `demo`)

2. **Descarga el script**:
   ```bash
   wget -O install-xoniant32-ultimate.sh https://raw.githubusercontent.com/XONIDU/xoniant32/main/install-xoniant32-ultimate.sh
   chmod +x install-xoniant32-ultimate.sh
   ```

3. **Ejecuta el instalador**:
   ```bash
   sudo ./install-xoniant32-ultimate.sh
   ```

4. **Reinicia** cuando termine.

### Opción 3: Instalar en antiX ya instalado

Si ya tienes antiX instalado en tu disco:

```bash
git clone https://github.com/XONIDU/xoniant32.git
cd xoniant32
chmod +x install-xoniant32-ultimate.sh
sudo ./install-xoniant32-ultimate.sh
sudo reboot
```

---

## 🎯 Primer inicio después de la instalación

- **Usuario**: el que tenías en antiX (o `demo` si no lo cambiaste)
- **Contraseña**: la misma que tenías

El sistema arrancará **directamente en una terminal negra ocupando toda la pantalla**. La terminal principal **NO SE PUEDE CERRAR**.

---

## ⌨️ Atajos de teclado

| Tecla | Acción |
|-------|--------|
| `Alt+Tab` | Cambiar entre ventanas emergentes |
| `Alt+F4` | Cerrar ventana actual (excepto la principal) |
| `Alt+F10` | Maximizar/restaurar ventana |
| `Win+↑` | Maximizar ventana |
| `Ctrl+Alt+T` | Abrir nueva terminal (emergente, encima de la principal) |
| `Win+x` | Abrir menú principal |
| `Win+q` | Cerrar sesión (única forma de salir) |

---

## 🖱️ Ratón y portapapeles

| Acción | Resultado |
|--------|-----------|
| **Seleccionar texto** | Copia automáticamente al portapapeles |
| **Click derecho** | Pega el texto copiado |
| `Ctrl+Shift+C` | Copiar selección |
| `Ctrl+Shift+V` | Pegar |
| `Ctrl+Insert` | Copiar |
| `Shift+Insert` | Pegar |

---

## 📦 Comandos XONI

| Comando | Descripción |
|---------|-------------|
| `xoni-install <herramienta>` | Instala herramienta XONI en `~/<herramienta>` y crea comando global |
| `xoni-update` | Actualiza xoniant32 desde GitHub (scripts y configuraciones) |
| `xoni-menu` | Abre menú interactivo |
| `xoni-help` | Muestra esta ayuda |

### Herramientas disponibles (desde XONIDU)

```bash
xoni-install xonitube    # Buscador y reproductor de YouTube
xoni-install xonigraf    # Graficador matemático
xoni-install xonichat    # Chat con IA (Gemini)
xoni-install xonimail    # Cliente de correo
# ... y más en https://github.com/XONIDU
```

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

---

## 🔊 Ajustar volumen (ALSA)

```bash
alsamixer
```

Usa flechas para subir/bajar volumen, `Esc` para salir.

---

## 🔄 Actualización del sistema

```bash
sudo xoni-update
```

Esto clona/actualiza el repositorio desde GitHub y sincroniza los cambios en `/usr/local/bin/`.

---

## 💻 Hardware soportado

### Mínimo
- **Procesador**: 32 bits (i386) – Intel Pentium III / Celeron o superior
- **RAM**: 512 MB (recomendado 1 GB)
- **Almacenamiento**: 8 GB
- **Gráficos**: Cualquier chip compatible com Xorg (todos los controladores se conservan)

### Probado en
- **ASUS Eee PC 900** (Intel Celeron M 900MHz, 1GB RAM, GMA 900)
- **ThinkPad X60** (Intel Core Duo, 32 bits)
- **VirtualBox / QEMU**

---

## 🛠️ Solución de problemas comunes

### ❌ El escritorio sigue apareciendo
```bash
# Verificar que Openbox está configurado como sesión por defecto
cat /etc/lightdm/lightdm.conf.d/50-xoniant32.conf
```

### ❌ No se conecta WiFi
```bash
sudo sv restart connman   # antiX usa runit
sudo connmanctl
# Vuelve a conectar
```

### ❌ El video de XoniTube no se ve
```bash
# Verificar que mpv tiene backend correcto
mpv --vo=help
# Probar manualmente
mpv --vo=x11 https://youtu.be/...
```

### ❌ No aparece el menú con Win+x
```bash
# Verificar que el archivo rc.xml tiene los atajos
grep "W-x" ~/.config/openbox/rc.xml
```

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

---

⭐ **Si te gusta el proyecto, no olvides dejar una estrella en GitHub** ⭐

