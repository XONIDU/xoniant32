# 🏔️ XONIARCH32 v4.2.0
### by Darian Alberto Camacho Salas

---

## 📋 Descripción

**XONIARCH32** es una distribución Linux ligera basada en **Arch Linux 32 bits**, diseñada específicamente para hardware antiguo y de bajos recursos.

### Características principales:
- **Gráfico siempre activo** - Inicia directamente en entorno gráfico
- **Terminal fija** - La terminal principal no se puede cerrar
- **Instalador de herramientas** - `installxoni` para instalar herramientas desde GitHub
- **Soporte completo de hardware** - Audio, video, red, WiFi, Bluetooth
- **Actualización desde GitHub**

---

## ⚠️ Advertencia

Este sistema es para **fines educativos**. El autor no se responsabiliza del uso que se le dé.

---

## 📥 Descargar Arch Linux 32 bits

### 🌐 Mirrors oficiales de Arch Linux 32

| Región | Mirror |
|--------|--------|
| **Alemania** | [de.mirror.archlinux32.org](http://de.mirror.archlinux32.org) |
| **Alemania** | [mirror.archlinux32.org](http://mirror.archlinux32.org) |
| **Bielorrusia** | [mirror.datacenter.by](http://mirror.datacenter.by) |
| **Canadá** | [mirror.qctronics.com](http://mirror.qctronics.com) |
| **Estados Unidos** | [mirror.clarkson.edu](http://mirror.clarkson.edu) |
| **Estados Unidos** | [mirror.math.princeton.edu](http://mirror.math.princeton.edu) |
| **Francia** | [archlinux32.agoctrl.org](http://archlinux32.agoctrl.org) |
| **Grecia** | [gr.mirror.archlinux32.org](http://gr.mirror.archlinux32.org) |
| **Polonia** | [mirror.juniorjpdj.pl](http://mirror.juniorjpdj.pl) |
| **Rusia** | [mirror.yandex.ru](http://mirror.yandex.ru) |
| **Suiza** | [archlinux32.andreasbaumann.cc](http://archlinux32.andreasbaumann.cc) |

### 📦 Descargar ISO

| Versión | Enlace |
|---------|--------|
| **Última versión (i686)** | [https://mirror.archlinux32.org/iso/latest/](https://mirror.archlinux32.org/iso/latest/) |
| **Release actual: 2024.07.10** | [Descargar ISO (796 MB)](https://mirror.archlinux32.org/iso/2024.07.10/archlinux32-2024.07.10-i686.iso) |

---

## 🚀 Instalación de XONIARCH32

### Paso 1: Instalar Arch Linux 32 bits base
Sigue la [guía oficial de instalación de Arch Linux](https://wiki.archlinux.org/title/Installation_guide) adaptada para 32 bits.

### Paso 2: Descargar e instalar XONIARCH32

```bash
# Como root, primero configura las claves PGP (necesario en sistema live)
pacman-key --init
pacman-key --populate archlinux32
pacman-key --refresh-keys

# Sincronizar bases de datos
pacman -Sy

# Instalar git
pacman -S git

# Clonar el repositorio
git clone https://github.com/XONIDU/xoniarch32.git
cd xoniarch32

# Ejecutar el instalador
bash xoniarch-install.sh

# Reiniciar
reboot
```

### ⚠️ Solución de errores comunes

#### Error: "signature is unknown trust" o "invalid or corrupted package (PGP signature)"

Este error ocurre cuando las claves PGP no están configuradas correctamente. Solución:

```bash
# Inicializar el llavero de claves
pacman-key --init

# Cargar claves de archlinux32
pacman-key --populate archlinux32
pacman-key --populate archlinux  # Opcional, para claves adicionales

# Actualizar claves
pacman-key --refresh-keys

# Sincronizar bases de datos e instalar
pacman -Sy git
```

#### Error: "database file for 'core' does not exist"

```bash
# Sincronizar bases de datos primero
pacman -Sy
```

#### Error: "target not found: git"

```bash
# Verificar que los repositorios están habilitados en /etc/pacman.conf
# Las líneas [core], [extra] y [community] NO deben estar comentadas

# Luego sincronizar e instalar
pacman -Sy git
```

---

## 📦 Uso después de la instalación

| Comando | Descripción |
|---------|-------------|
| `installxoni <herramienta>` | Instalar herramienta XONI |
| `xoniarch-help` | Ayuda |
| `xoniarch-menu` | Menú interactivo |
| `nmtui` | Configurar red |
| `htop` | Monitor del sistema |

### Atajos:
- `Windows + x` - Menú
- `Windows + t` - Nueva terminal
- `Windows + h` - Ayuda
- `Windows + i` - Instalar herramienta

---

## 🛠️ Herramientas XONI disponibles

```bash
installxoni xonitube    # Reproductor de videos
installxoni xonigraf    # Graficador
installxoni xonichat    # Chat con IA
installxoni xonimail    # Cliente de correo
installxoni xoniencript # Cifrado
installxoni xoniweb     # Análisis web
installxoni xonidip     # Diplomas
installxoni xonidate    # Citas aleatorias
installxoni xoniconver  # Conversor
installxoni xoniter     # Comandos
installxoni xonial      # Monitoreo
installxoni xonispam    # Pruebas éticas
```

---

## 🔧 Requisitos del sistema

- **Procesador**: 32 bits (Intel Pentium III / Celeron)
- **RAM**: 512 MB (1 GB recomendado)
- **Almacenamiento**: 8 GB
- **Base**: Arch Linux 32 bits

---

## ✉️ Contacto

- **Email**: xonidu@gmail.com
- **Creador**: Darian Alberto Camacho Salas
- **Web**: [https://xonipage.xonidu.com/](https://xonipage.xonidu.com/)
- **GitHub**: [@XONIDU](https://github.com/XONIDU)

---

## 🌐 Enlaces útiles

- [Repositorio XONIARCH32](https://github.com/XONIDU/xoniarch32)
- [Arch Linux 32 Official](https://archlinux32.org/)
- [Guía de instalación de Arch Linux](https://wiki.archlinux.org/title/Installation_guide)
- [XONIPAGE](https://xonipage.xonidu.com/)
- [XONIENCRIPT](https://xoniencript.xonidu.com/)
- [XONITRES](https://xonitres.xonidu.com/)
```

Este README ahora incluye:
- ✅ Pasos detallados para solucionar errores de PGP
- ✅ Comandos para inicializar `pacman-key`
- ✅ Solución a errores comunes como "target not found" y "database file does not exist"
- ✅ Instrucciones claras para instalar git y clonar el repositorio
