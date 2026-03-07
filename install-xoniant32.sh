#!/bin/bash
# xoniant32 – Script de purga y conversión desde antiX
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script convierte una instalación existente de antiX 386
# en un sistema xoniant32 puro: solo terminal, sin escritorios,
# con Openbox como única ventana, terminal fija, audio, nmtui,
# y scripts XONI.

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Falló en la línea $LINENO\033[0m" >&2' ERR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info()  { echo -e "${GREEN}[INFO] $1${NC}"; }
warn()  { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    error_exit "Este script debe ejecutarse como root (sudo)."
fi

# Verificar que es antiX
if [ ! -f /etc/antix-version ]; then
    error_exit "Este script debe ejecutarse en antiX Linux."
fi

clear
echo "========================================"
echo "   XONIANT32 - PURGA Y CONVERSIÓN      "
echo "   desde antiX 386                      "
echo "========================================"
echo "ADVERTENCIA: Este script eliminará:"
echo "  - Todos los entornos de escritorio (XFCE, Fluxbox, IceWM, JWM)"
echo "  - Aplicaciones innecesarias (libreoffice, firefox-esr, etc.)"
echo "  - Juegos, herramientas gráficas, y paquetes de desarrollo"
echo "========================================"
echo ""
read -p "¿Estás seguro de continuar? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Operación cancelada."

# ============================================
# 1. PURGA MASIVA DE PAQUETES INNECESARIOS
# ============================================
info "Purgando entornos de escritorio completos..."
apt purge -y xfce4* lxde* lxqt* mate-* cinnamon* gnome-* kde-* || true

info "Purgando gestores de ventanas adicionales..."
apt purge -y fluxbox icewm jwm dwm awesome i3* || true

info "Purgando aplicaciones de oficina..."
apt purge -y libreoffice* abiword gnumeric || true

info "Purgando navegadores pesados..."
apt purge -y firefox* chromium* seamonkey* || true

info "Purgando reproductores multimedia..."
apt purge -y vlc smplayer audacious parole || true

info "Purgando juegos y entretenimiento..."
apt purge -y gnome-games* aisleriot solitaire || true

info "Purgando herramientas gráficas..."
apt purge -y gimp inkscape blender shotwell || true

info "Purgando clientes de correo..."
apt purge -y thunderbird* claws-mail* sylpheed* || true

info "Purgando programas de desarrollo innecesarios..."
apt purge -y build-essential gcc g++ make cmake || true

info "Purgando documentación y manuales..."
apt purge -y man-db manpages info || true

# ============================================
# 2. AUTOLIMPIEZA
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando caché de paquetes..."
apt clean
apt autoclean

# ============================================
# 3. INSTALAR PAQUETES ESENCIALES XONIANT32
# ============================================
info "Instalando paquetes esenciales..."

# Actualizar repositorios
apt update

# Paquetes base
apt install -y git curl wget htop nano

# Audio
apt install -y alsa-utils pulseaudio pavucontrol

# Red
apt install -y network-manager network-manager-gnome nmtui

# Xorg mínimo
apt install -y xorg xserver-xorg-core xserver-xorg-input-all xserver-xorg-video-fbdev

# Openbox y terminal fija
apt install -y openbox obconf tint2 feh picom rxvt-unicode pcmanfm

# Scripts XONI (dependencia git)
apt install -y git

# ============================================
# 4. ELIMINAR GESTORES DE DISPLAY PESADOS
# ============================================
info "Eliminando gestores de display..."
apt purge -y lightdm sddm lxdm slim gdm3 xdm || true

# ============================================
# 5. CONFIGURAR OPENBOX (TERMINAL FIJA)
# ============================================
info "Configurando Openbox con terminal fija..."

# Crear estructura de directorios para usuario (si existe)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME="/home/$SUDO_USER"
else
    # Si no hay SUDO_USER, preguntar
    read -p "Nombre de usuario para configurar: " TARGET_USER
    USER_HOME="/home/$TARGET_USER"
fi

mkdir -p "$USER_HOME/.config/openbox"

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

cat > "$USER_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e installxoni</command></action></item>
    <item label="Configurar red"><action name="Execute"><command>urxvt -e nmtui</command></action></item>
    <item label="Monitor sistema"><action name="Execute"><command>urxvt -e htop</command></action></item>
    <item label="Ayuda"><action name="Execute"><command>urxvt -e xoniarch-help</command></action></item>
    <item label="Cerrar sesión"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
urxvt -title "principal" &
feh --bg-scale /usr/share/backgrounds/default.jpg &
picom -b &
tint2 &
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

chown -R "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" 2>/dev/null || true

# ============================================
# 6. CREAR SCRIPTS XONI (en /usr/local/bin)
# ============================================
info "Creando scripts XONI..."

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
echo "[OK] Actualización completada"
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
  xoniarch-menu              : Menú interactivo
  nmtui                      : Configurar red
  htop                       : Monitor del sistema

ATAJOS:
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + i   : Instalar herramienta
  Win + q   : Cerrar sesión

El sistema ARRANCA DIRECTAMENTE EN MODO GRÁFICO
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
    echo "3) Configurar red (nmtui)"
    echo "4) Monitor del sistema (htop)"
    echo "5) Ayuda"
    echo "6) Cerrar sesión"
    echo ""
    read -p "Opción [1-6]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e installxoni ; read -p "Presiona Enter..." ;;
        3) urxvt -e nmtui ;;
        4) urxvt -e htop ;;
        5) xoniarch-help ; read -p "Presiona Enter..." ;;
        6) openbox --exit ;;
        *) echo "Opción inválida"; sleep 2 ;;
    esac
done
EOF

chmod +x /usr/local/bin/*

# ============================================
# 7. CONFIGURAR ARRANQUE SIN GESTOR DE DISPLAY
# ============================================
info "Configurando arranque automático a X..."

# Añadir al .bashrc del usuario para iniciar X en tty1
cat >> "$USER_HOME/.bashrc" << 'BASHRC'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
BASHRC

# Configurar getty para auto-login (opcional)
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $SUDO_USER --noclear %I 38400 linux
EOF

# ============================================
# 8. CONFIGURAR NETWORKMANAGER PARA runit
# ============================================
info "Configurando NetworkManager para antiX (runit)..."

mkdir -p /etc/sv/networkmanager
cat > /etc/sv/networkmanager/run << 'EOF'
#!/bin/bash
exec chpst -u root /usr/sbin/NetworkManager
EOF
chmod +x /etc/sv/networkmanager/run

ln -s /etc/sv/networkmanager /etc/service/networkmanager 2>/dev/null || true

# ============================================
# 9. .bashrc personalizado
# ============================================
cat >> "$USER_HOME/.bashrc" << 'BASHRC2'
alias ll='ls -la'
alias la='ls -A'
alias update='xoniarch-update'
alias menu='xoniarch-menu'
alias help='xoniarch-help'
BASHRC2

chown "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.bashrc"

# ============================================
# 10. LIMPIEZA FINAL Y MENSAJE
# ============================================
info "Limpiando paquetes huérfanos finales..."
apt autoremove --purge -y
apt clean

echo "========================================"
echo "   CONVERSIÓN COMPLETADA                "
echo "========================================"
echo ""
echo "✅ antiX ha sido transformado en xoniant32"
echo "📦 Paquetes eliminados: entornos de escritorio, apps pesadas"
echo "🎯 Solo queda: Openbox + terminal fija + scripts XONI"
echo ""
echo "Recomendaciones:"
echo "1. Reinicia el sistema: sudo reboot"
echo "2. Al arrancar, entrarás directamente a X con la terminal fija"
echo "3. Usa 'xoniarch-help' para ver los comandos disponibles"
echo ""
echo "Usuario: $SUDO_USER"
echo "Contraseña: la misma de antiX"
echo ""
echo "¡Disfruta tu xoniant32 minimalista!"
