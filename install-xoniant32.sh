#!/bin/bash
# xoniant32 – Script de purga ULTRA minimalista
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script elimina TODO lo innecesario y deja SOLO:
#   - Openbox (ventanas minimas)
#   - Una terminal fija que ocupa toda la pantalla
#   - Audio (ALSA)
#   - Connman para WiFi (nativo de antiX)
#   - Scripts XONI
#   - NADA MAS (ni tint2, ni feh, ni picom, ni escritorio)

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Fallo en la linea $LINENO\033[0m" >&2' ERR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info()  { echo -e "${GREEN}[INFO] $1${NC}"; }
warn()  { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    error_exit "Este script debe ejecutarse como root (sudo)."
fi

# Verificar antiX
if [ ! -f /etc/antix-version ]; then
    error_exit "Este script debe ejecutarse en antiX Linux."
fi

clear
echo "========================================"
echo "   XONIANT32 - PURGA ULTRA              "
echo "========================================"
echo "ADVERTENCIA: Este script ELIMINARA:"
echo "  - TODOS los escritorios"
echo "  - TODAS las aplicaciones"
echo "  - TODOS los gestores de display"
echo "  - Barras de tareas, fondos, compositores"
echo ""
echo "SOLO DEJARA:"
echo "  - Openbox (minimo)"
echo "  - Terminal fija (rxvt-unicode)"
echo "  - ALSA para audio"
echo "  - Connman para WiFi"
echo "  - Scripts XONI"
echo "========================================"
echo ""
read -p "¿Estas seguro? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Operacion cancelada."

# ============================================
# 1. PURGA MASIVA
# ============================================
info "Purgando escritorios completos..."
apt purge -y xfce4* lxde* lxqt* mate-* cinnamon* gnome-* kde-* || true

info "Purgando gestores de ventanas adicionales..."
apt purge -y fluxbox icewm jwm dwm awesome i3* || true

info "Purgando aplicaciones graficas..."
apt purge -y firefox* chromium* seamonkey* libreoffice* abiword gnumeric || true
apt purge -y vlc smplayer audacious parole gimp inkscape blender shotwell || true
apt purge -y thunderbird* claws-mail* sylpheed* || true
apt purge -y gnome-games* aisleriot solitaire || true

info "Purgando gestores de display..."
apt purge -y lightdm sddm lxdm slim gdm3 xdm || true

info "Purgando NetworkManager y nmtui..."
apt purge -y network-manager* nmtui || true

info "Purgando herramientas de escritorio (tint2, feh, picom)..."
apt purge -y tint2 feh picom nitrogen || true

info "Purgando herramientas de desarrollo..."
apt purge -y build-essential gcc g++ make cmake || true

info "Purgando documentacion..."
apt purge -y man-db manpages info || true

# ============================================
# 2. AUTOLIMPIEZA
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando cache..."
apt clean
apt autoclean

# ============================================
# 3. INSTALAR PAQUETES MINIMOS
# ============================================
info "Instalando paquetes minimos..."

apt update

# Base minima
apt install -y git curl wget htop nano

# Audio (ALSA puro)
apt install -y alsa-utils

# Xorg minimo
apt install -y xorg xserver-xorg-core xserver-xorg-input-all xserver-xorg-video-fbdev

# Openbox y terminal (SOLO lo necesario)
apt install -y openbox rxvt-unicode

# Connman (WiFi nativo)
apt install -y connman

# ============================================
# 4. CONFIGURAR OPENBOX (TERMINAL FIJA)
# ============================================
info "Configurando Openbox con terminal fija..."

# Determinar usuario
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
else
    read -p "Nombre de usuario para configurar: " TARGET_USER
fi
USER_HOME="/home/$TARGET_USER"

mkdir -p "$USER_HOME/.config/openbox"

# Configuracion de Openbox - TERMINAL FIJA sin decoraciones
cat > "$USER_HOME/.config/openbox/rc.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config>
  <applications>
    <application class="URxvt" name="urxvt" title="principal">
      <decor>no</decor>
      <maximized>yes</maximized>
      <focus>yes</focus>
      <desktop>all</desktop>
      <layer>above</layer>
    </application>
  </applications>
  <menu><file>~/.config/openbox/menu.xml</file></menu>
  <keyboard>
    <keybind key="W-x"><action name="Execute"><command>xoniarch-menu</command></action></keybind>
    <keybind key="W-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="W-h"><action name="Execute"><command>xoniarch-help</command></action></keybind>
    <keybind key="W-i"><action name="Execute"><command>installxoni</command></action></keybind>
    <keybind key="W-q"><action name="Exit"/></keybind>
  </keyboard>
</openbox_config>
EOF

# Menu minimalista
cat > "$USER_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e installxoni</command></action></item>
    <item label="Ayuda"><action name="Execute"><command>urxvt -e xoniarch-help</command></action></item>
    <item label="Cerrar sesion"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

# Autostart - SOLO la terminal principal (sin barra, sin fondo, sin compositor)
cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR) - SIN NADA MAS
urxvt -title "principal" &
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc"

# ============================================
# 5. CONFIGURAR CONNMAN (WiFi)
# ============================================
info "Configurando Connman..."

# Asegurar que connman este habilitado en runit
mkdir -p /etc/sv/connman
cat > /etc/sv/connman/run << 'EOF'
#!/bin/bash
exec chpst -u root /usr/sbin/connmand -n
EOF
chmod +x /etc/sv/connman/run

ln -s /etc/sv/connman /etc/service/connman 2>/dev/null || true

# Archivo de ayuda para WiFi
cat > "$USER_HOME/.wifi-help" << 'EOF'
========================================
   CONECTARSE A WIFI
========================================

Comando: sudo connmanctl

Dentro de connmanctl:
  agent on                  # Activar agente
  enable wifi               # Habilitar WiFi
  scan wifi                 # Escanear redes
  services                  # Listar redes
  connect wifi_nombre       # Conectar (TAB autocompleta)
  quit                      # Salir

Ejemplo:
  $ sudo connmanctl
  connmanctl> agent on
  connmanctl> enable wifi
  connmanctl> scan wifi
  connmanctl> services
  connmanctl> connect wifi_MiRed_managed_psk
  connmanctl> quit
EOF

chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.wifi-help"

# ============================================
# 6. CREAR SCRIPTS XONI
# ============================================
info "Creando scripts XONI..."

mkdir -p /usr/local/bin

cat > /usr/local/bin/installxoni << 'EOF'
#!/bin/bash
REPO_BASE="https://github.com/XONIDU"
DIR="/opt/xoniarch"
[ ! -d "$DIR" ] && mkdir -p "$DIR"
cd "$DIR"
TOOL="${1:-}"
if [ -z "$TOOL" ]; then
    read -p "Herramienta a instalar (ej: xonitube): " TOOL
fi
if [ -d "$TOOL" ]; then
    cd "$TOOL" && git pull
else
    git clone "$REPO_BASE/$TOOL.git"
fi
find "$TOOL" -name "*.py" -o -name "*.sh" -exec chmod +x {} \;
echo "[OK] $TOOL instalado"
EOF

cat > /usr/local/bin/xoniarch-update << 'EOF'
#!/bin/bash
cd /opt/xoniarch
for tool in */; do
    [ -d "$tool" ] && (cd "$tool" && git pull)
done
echo "[OK] Actualizacion completada"
EOF

cat > /usr/local/bin/xoniarch-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIANT32 - AYUDA
========================================
COMANDOS:
  installxoni <herramienta>  : Instalar desde GitHub
  xoniarch-update            : Actualizar herramientas
  xoniarch-menu              : Menu interactivo
  sudo connmanctl            : Configurar WiFi

AUDIO:
  alsamixer                  : Ajustar volumen
  speaker-test               : Probar audio

ATAJOS:
  Win + x   : Menu principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + i   : Instalar herramienta
  Win + q   : Cerrar sesion

El sistema ARRANCA DIRECTAMENTE EN MODO GRAFICO
La terminal principal es FIJA (no se puede cerrar)

REPOSITORIO: https://github.com/XONIDU/xoniant32
HELP
EOF

cat > /usr/local/bin/xoniarch-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "========================================"
    echo "      XONIANT32 - MENU PRINCIPAL"
    echo "========================================"
    echo "1) Nueva terminal"
    echo "2) Instalar herramienta XONI"
    echo "3) Ayuda"
    echo "4) Cerrar sesion"
    echo ""
    read -p "Opcion [1-4]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e installxoni ; read -p "Presiona Enter..." ;;
        3) xoniarch-help ; read -p "Presiona Enter..." ;;
        4) openbox --exit ;;
        *) echo "Opcion invalida"; sleep 2 ;;
    esac
done
EOF

chmod +x /usr/local/bin/*

# ============================================
# 7. CONFIGURAR ARRANQUE AUTOMATICO
# ============================================
info "Configurando arranque automatico a X..."

# Auto-login en tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I 38400 linux
EOF

# Arranque de X en .bashrc
cat >> "$USER_HOME/.bashrc" << 'BASHRC'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi

alias ll='ls -la'
alias la='ls -A'
alias update='xoniarch-update'
alias menu='xoniarch-menu'
alias help='xoniarch-help'
alias wifi='sudo connmanctl'
BASHRC

chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.bashrc"

# ============================================
# 8. MENSAJE DE BIENVENIDA (SIN EMOJIS)
# ============================================
cat > /etc/motd << 'EOF'
========================================
   XONIANT32 - LISTO
   by Darian Alberto Camacho Salas
========================================

El sistema arranca directamente en modo grafico.
La terminal principal es FIJA (no se puede cerrar).

Comandos utiles:
  xoniarch-help     : Ayuda completa
  xoniarch-menu     : Menu interactivo
  sudo connmanctl   : Conectar a WiFi (ver ~/.wifi-help)
  alsamixer         : Ajustar volumen

Repositorio: https://github.com/XONIDU/xoniant32
========================================
EOF

# ============================================
# 9. LIMPIEZA FINAL
# ============================================
info "Limpiando paquetes residuales..."
apt autoremove --purge -y
apt clean

echo "========================================"
echo "   PURGA COMPLETADA                     "
echo "========================================"
echo ""
echo "antiX ha sido transformado en xoniant32"
echo ""
echo "SOLO QUEDA:"
echo "  - Openbox (minimo)"
echo "  - Terminal fija (rxvt-unicode)"
echo "  - ALSA para audio"
echo "  - Connman para WiFi"
echo "  - Scripts XONI"
echo ""
echo "NO HAY:"
echo "  - Escritorios"
echo "  - Barras de tareas"
echo "  - Fondos de pantalla"
echo "  - Gestores de display"
echo ""
echo "WiFi: cat ~/.wifi-help"
echo ""
echo "Reinicia con: sudo reboot"
echo ""
echo "Usuario: $TARGET_USER"
echo "Contrasena: la misma de antiX"
echo ""
echo "¡Disfruta xoniant32!"
