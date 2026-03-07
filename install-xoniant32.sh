#!/bin/bash
# install-xoniant32.sh – Instalador base de xoniant32 (repos en home)
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Falló en la línea $LINENO\033[0m" >&2' ERR

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
echo "   XONIANT32 - INSTALADOR BASE         "
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo "ADVERTENCIA: Este script ELIMINARÁ:"
echo "  - TODOS los escritorios completos"
echo "  - TODAS las aplicaciones gráficas pesadas"
echo "  - TODOS los gestores de display"
echo "  - Barras de tareas, fondos, compositores"
echo "  - NetworkManager (usaremos connman nativo)"
echo "  - Scripts antiguos (xoniarch-*)"
echo ""
echo "CONSERVARÁ:"
echo "  - Openbox con terminal fija"
echo "  - ALSA para audio"
echo "  - Connman para WiFi"
echo "  - mpv + yt-dlp (para xonitube)"
echo "  - Scripts XONI (xoni-install, xoni-update, xoni-help, xoni-menu)"
echo "  - Las herramientas XONI se instalarán en /home/tu_usuario/xoni/"
echo ""
read -p "¿Estás seguro? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Operación cancelada."

# ============================================
# 1. PURGA MASIVA
# ============================================
info "Purgando escritorios completos..."
apt purge -y xfce4* lxde* lxqt* mate-* cinnamon* gnome-* kde-* || true

info "Purgando gestores de ventanas adicionales..."
apt purge -y fluxbox icewm jwm dwm awesome i3* || true

info "Purgando aplicaciones gráficas pesadas..."
apt purge -y firefox* chromium* seamonkey* libreoffice* abiword gnumeric || true
apt purge -y vlc smplayer audacious parole gimp inkscape blender shotwell || true
apt purge -y thunderbird* claws-mail* sylpheed* || true
apt purge -y gnome-games* aisleriot solitaire || true

info "Purgando gestores de display..."
apt purge -y lightdm sddm lxdm slim gdm3 xdm || true

info "Purgando NetworkManager y nmtui..."
apt purge -y network-manager* nmtui || true

info "Purgando herramientas de escritorio (tint2, feh, picom, nitrogen)..."
apt purge -y tint2 feh picom nitrogen || true

info "Purgando herramientas de desarrollo (opcional)..."
apt purge -y build-essential gcc g++ make cmake || true

info "Purgando documentación..."
apt purge -y man-db manpages info || true

# ============================================
# 2. ELIMINAR RASTROS DE XONIARCH
# ============================================
info "Eliminando rastros de xoniarch..."
rm -f /usr/local/bin/xoniarch-* 2>/dev/null || true
rm -f /usr/local/bin/xoniarch 2>/dev/null || true
rm -f /usr/local/bin/xoniarch32 2>/dev/null || true
rm -rf /opt/xoniarch 2>/dev/null || true
rm -rf /opt/xoniarch32 2>/dev/null || true

# ============================================
# 3. AUTOLIMPIEZA
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando caché..."
apt clean
apt autoclean

# ============================================
# 4. INSTALAR PAQUETES MÍNIMOS + SOPORTE XONITUBE
# ============================================
info "Actualizando repositorios..."
apt update || warn "Error en apt update, continuando..."

info "Instalando paquetes base y multimedia..."
apt install -y git curl wget htop nano alsa-utils xorg openbox rxvt-unicode connman
apt install -y mpv yt-dlp ffmpeg
apt install -y --fix-missing adwaita-icon-theme gnome-themes-extra || warn "Temas GTK opcionales no instalados."

# ============================================
# 5. CONFIGURAR MPV PARA VIDEO (BACKEND X11)
# ============================================
info "Configurando mpv para que el video funcione siempre..."
mkdir -p /etc/mpv
cat > /etc/mpv/mpv.conf << 'EOF'
# Configuración global de mpv para xoniant32
vo=x11
ao=alsa
cache=yes
cache-secs=30
profile=fast
msg-level=all=error
EOF

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"

mkdir -p "$USER_HOME/.config/mpv"
cp /etc/mpv/mpv.conf "$USER_HOME/.config/mpv/"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config/mpv"

# ============================================
# 6. CONFIGURAR OPENBOX (TERMINAL FIJA)
# ============================================
info "Configurando Openbox con terminal fija..."

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
    <keybind key="W-x"><action name="Execute"><command>xoni-menu</command></action></keybind>
    <keybind key="W-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="W-h"><action name="Execute"><command>xoni-help</command></action></keybind>
    <keybind key="W-u"><action name="Execute"><command>xoni-update</command></action></keybind>
    <keybind key="W-q"><action name="Exit"/></keybind>
  </keyboard>
</openbox_config>
EOF

cat > "$USER_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e xoni-install</command></action></item>
    <item label="Configurar red (connman)"><action name="Execute"><command>urxvt -e sudo connmanctl</command></action></item>
    <item label="Monitor sistema"><action name="Execute"><command>urxvt -e htop</command></action></item>
    <item label="Actualizar xoniant32"><action name="Execute"><command>urxvt -e xoni-update</command></action></item>
    <item label="Ayuda"><action name="Execute"><command>urxvt -e xoni-help</command></action></item>
    <item label="Cerrar sesión"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
urxvt -title "principal" &
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

# Auto-login en tty1
cat >> "$USER_HOME/.bashrc" << 'EOF'

# Iniciar X automáticamente en tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF

# Mensaje de bienvenida
cat >> "$USER_HOME/.bashrc" << 'EOF'

# Mensaje de bienvenida de Xoniant32
echo "========================================"
echo "   XONIANT32 by Darian Alberto Camacho Salas"
echo "========================================"
echo "Comandos útiles:"
echo "  xoni-help     : Muestra esta ayuda"
echo "  xoni-menu     : Menú interactivo"
echo "  xoni-update   : Actualiza xoniant32 y herramientas en ~/xoni/"
echo "  xoni-install  : Instala herramientas XONI en ~/xoni/ (ej: xoni-install xonitube)"
echo "  sudo connmanctl : Configura la red WiFi"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"

# ============================================
# 7. CREAR SCRIPTS XONI PRINCIPALES (VERSIÓN HOME)
# ============================================
info "Creando scripts XONI (con repositorios en home)..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
# xoni-install – Instalador de herramientas XONI en ~/xoni/
# Autor: Darian Alberto Camacho Salas

REPO_BASE="https://github.com/XONIDU"
XONI_DIR="$HOME/xoni"
mkdir -p "$XONI_DIR"
cd "$XONI_DIR"

if [ -n "$1" ]; then
    TOOL="$1"
    echo "Instalando $TOOL desde $REPO_BASE/$TOOL.git en $XONI_DIR/$TOOL ..."
    
    if [ -d "$TOOL" ]; then
        echo "Actualizando $TOOL existente..."
        cd "$TOOL" && git pull && cd ..
    else
        git clone "$REPO_BASE/$TOOL.git"
    fi
    
    # Buscar el archivo principal y crear enlace en /usr/local/bin (pide sudo)
    if [ -f "$TOOL/start.py" ]; then
        echo "Se necesita sudo para copiar el script a /usr/local/bin/"
        sudo cp "$TOOL/start.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL instalado en /usr/local/bin/$TOOL"
    elif [ -f "$TOOL/$TOOL.py" ]; then
        sudo cp "$TOOL/$TOOL.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL instalado en /usr/local/bin/$TOOL"
    elif [ -f "$TOOL/$TOOL.sh" ]; then
        sudo cp "$TOOL/$TOOL.sh" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL instalado en /usr/local/bin/$TOOL"
    else
        echo "[AVISO] No se encontró archivo principal, pero el repositorio está en $XONI_DIR/$TOOL"
    fi

else
    echo "Herramientas disponibles en XONIDU:"
    echo "  xonitube, xonigraf, xonichat, xonimail, xonicar, xoniclus, xoniconver, xonidate, xonidal, xonidip, xoniencript, xonihelp, xonilab, xoniclient, xoniserver, xoniterm, xonifs, xonigrep, xonisearch, xonicrypt, xonidecode, xonicron, xonisync"
    echo ""
    read -p "Herramienta a instalar: " TOOL
    if [ -n "$TOOL" ]; then
        exec "$0" "$TOOL"
    else
        echo "No se especificó ninguna herramienta."
    fi
fi
EOF

cat > /usr/local/bin/xoni-update << 'EOF'
#!/bin/bash
# xoni-update – Actualiza xoniant32 y las herramientas XONI en ~/xoni/
# Autor: Darian Alberto Camacho Salas

# Actualizar scripts del sistema (requiere sudo)
REPO="https://github.com/XONIDU/xoniant32.git"
DIR="/opt/xoniant32"
echo "Actualizando scripts de xoniant32 (se necesita sudo)..."
if [ ! -d "$DIR" ]; then
    sudo git clone "$REPO" "$DIR"
else
    cd "$DIR" && sudo git pull
fi

if [ -d "$DIR/scripts" ]; then
    sudo cp -v "$DIR/scripts"/xoni-* /usr/local/bin/ 2>/dev/null || true
fi

sudo rm -f /usr/local/bin/xoniarch-* 2>/dev/null || true
sudo chmod +x /usr/local/bin/xoni-* 2>/dev/null || true

# Actualizar herramientas en ~/xoni/ (sin sudo)
XONI_DIR="$HOME/xoni"
if [ -d "$XONI_DIR" ]; then
    echo ""
    echo "Actualizando herramientas en $XONI_DIR ..."
    cd "$XONI_DIR"
    for tool in */; do
        if [ -d "$tool" ]; then
            echo "Actualizando ${tool%/}..."
            cd "$tool" && git pull && cd ..
        fi
    done
else
    echo "No existe el directorio $XONI_DIR, no hay herramientas instaladas."
fi

echo "[OK] xoniant32 actualizado correctamente"
EOF

cat > /usr/local/bin/xoni-help << 'EOF'
#!/bin/bash
# xoni-help – Muestra ayuda de xoniant32

cat << 'HELP'
========================================
   XONIANT32 - AYUDA
========================================
COMANDOS PRINCIPALES:
  xoni-help                    : Muestra esta ayuda
  xoni-menu                    : Menú interactivo
  xoni-update                  : Actualiza scripts del sistema y herramientas en ~/xoni/
  xoni-install <herramienta>   : Instala herramientas XONI en ~/xoni/ y las deja disponibles

HERRAMIENTAS DISPONIBLES (desde XONIDU):
  xonitube, xonigraf, xonichat, xonimail, xonicar, xoniclus, xoniconver, xonidate, xonidal, xonidip, xoniencript, xonihelp, xonilab, xoniclient, xoniserver, xoniterm, xonifs, xonigrep, xonisearch, xonicrypt, xonidecode, xonicron, xonisync

ATAJOS DE TECLADO (en Openbox):
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + u   : Actualizar sistema
  Win + q   : Cerrar sesión

El sistema arranca directamente en modo gráfico.
La terminal principal es fija (no se puede cerrar).

REPOSITORIO: https://github.com/XONIDU/xoniant32
========================================
HELP
EOF

cat > /usr/local/bin/xoni-menu << 'EOF'
#!/bin/bash
# xoni-menu – Menú interactivo

while true; do
    clear
    echo "========================================"
    echo "      XONIANT32 - MENÚ PRINCIPAL"
    echo "========================================"
    echo "1) Nueva terminal"
    echo "2) Instalar herramienta XONI"
    echo "3) Configurar red (connman)"
    echo "4) Monitor del sistema (htop)"
    echo "5) Actualizar xoniant32"
    echo "6) Ayuda"
    echo "7) Cerrar sesión"
    echo ""
    read -p "Opción [1-7]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e xoni-install ; read -p "Presiona Enter..." ;;
        3) urxvt -e sudo connmanctl ;;
        4) urxvt -e htop ;;
        5) urxvt -e xoni-update ; read -p "Presiona Enter..." ;;
        6) xoni-help ; read -p "Presiona Enter..." ;;
        7) openbox --exit ;;
        *) echo "Opción inválida"; sleep 2 ;;
    esac
done
EOF

chmod +x /usr/local/bin/xoni-*

# ============================================
# 8. ACTUALIZAR MOTD
# ============================================
cat > /etc/motd << 'EOF'
========================================
   XONIANT32 - by Darian Alberto Camacho Salas
========================================
Comandos útiles:
  xoni-help     : Muestra esta ayuda
  xoni-menu     : Menú interactivo
  xoni-update   : Actualiza scripts y herramientas en ~/xoni/
  xoni-install  : Instala herramientas XONI en ~/xoni/ (ej: xoni-install xonitube)
  sudo connmanctl : Configura la red WiFi
  xonitube      : (después de instalarlo) Buscador de YouTube

El sistema arranca directamente en modo gráfico.
La terminal principal es fija (no se puede cerrar).

Repositorio: https://github.com/XONIDU/xoniant32
========================================
EOF

# ============================================
# 9. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN BASE COMPLETADA          "
echo "========================================"
echo ""
echo "antiX ha sido transformado en xoniant32"
echo ""
echo "Componentes instalados:"
echo "  - Openbox con terminal fija"
echo "  - ALSA (audio)"
echo "  - Connman (WiFi)"
echo "  - mpv + yt-dlp (listos para xonitube)"
echo "  - Scripts XONI: xoni-install, xoni-update, xoni-help, xoni-menu"
echo ""
echo "Las herramientas XONI se instalarán en: ~/xoni/"
echo "Para instalar xonitube, ejecuta: xoni-install xonitube"
echo ""
echo "Reinicia el sistema para aplicar los cambios: sudo reboot"
echo ""
echo "Usuario: $TARGET_USER (contraseña sin cambios)"
echo ""
echo "¡Disfruta xoniant32!"
