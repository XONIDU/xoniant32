#!/bin/bash
# install-xoniant32.sh – Terminal gráfica fija como inicio por defecto
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniant32
#
# Este script NO ELIMINA NINGÚN COMPONENTE DEL SISTEMA.
# Solo configura Openbox como sesión por defecto con terminal fija.
# Al arrancar, el sistema iniciará DIRECTAMENTE en una terminal maximizada
# sin mostrar escritorio. La terminal NO SE PUEDE CERRAR.
# Las herramientas XONI se instalan directamente en ~/ y están disponibles
# como comandos globales mediante enlaces simbólicos.

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
echo "   XONIANT32 - TERMINAL FIJA POR DEFECTO"
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo "Este script NO ELIMINA NINGÚN COMPONENTE."
echo "Solo AÑADE y CONFIGURA:"
echo "  - Openbox como sesión por defecto"
echo "  - Terminal fija (maximizada, sin bordes, NO SE PUEDE CERRAR)"
echo "  - Configuración óptima para mpv y yt-dlp"
echo "  - Scripts XONI (xoni-install, xoni-update, xoni-help, xoni-menu)"
echo "  - Las herramientas XONI se instalan DIRECTAMENTE en ~/ (ej: ~/xonitube)"
echo ""
read -p "¿Continuar? (s/n): " CONFIRM
[[ "$CONFIRM" =~ ^[Ss]$ ]] || error_exit "Operación cancelada."

# ============================================
# 1. ACTUALIZAR REPOSITORIOS
# ============================================
info "Actualizando repositorios..."
apt update || warn "Error en apt update, continuando..."

# ============================================
# 2. INSTALAR PAQUETES NECESARIOS
# ============================================
info "Instalando paquetes necesarios..."
apt install -y git curl wget htop nano alsa-utils connman
apt install -y xorg openbox rxvt-unicode
apt install -y mpv yt-dlp ffmpeg
apt install -y firmware-atheros firmware-iwlwifi firmware-realtek || warn "Algún firmware WiFi no se pudo instalar."
apt install -y --fix-missing adwaita-icon-theme || warn "Temas GTK opcionales no instalados."

# ============================================
# 3. CONFIGURAR CONNMAN
# ============================================
info "Configurando connman para WiFi estable..."
mkdir -p /etc/connman
cat > /etc/connman/main.conf << 'EOF'
[General]
PreferredTechnologies = wifi,ethernet
AllowHostnames = true
SingleConnectedTechnology = false
AutoConnect = true
NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb
EOF

systemctl restart connman || sv restart connman || true

# ============================================
# 4. CONFIGURAR MPV
# ============================================
info "Configurando mpv..."
mkdir -p /etc/mpv
cat > /etc/mpv/mpv.conf << 'EOF'
vo=x11
ao=alsa
cache=yes
cache-secs=30
profile=fast
msg-level=all=error
x11-bypass-compositor=yes
EOF

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"

mkdir -p "$USER_HOME/.config/mpv"
cp /etc/mpv/mpv.conf "$USER_HOME/.config/mpv/"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config/mpv"

# ============================================
# 5. CONFIGURAR OPENBOX (TERMINAL FIJA)
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

# ============================================
# 6. FORZAR OPENBOX COMO SESIÓN POR DEFECTO
# ============================================
info "Configurando Openbox como sesión por defecto..."

# Crear archivo de sesión para gestores de display
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/openbox.desktop << 'EOF'
[Desktop Entry]
Name=Openbox
Comment=Openbox Window Manager
Exec=openbox-session
Type=Application
EOF

# LightDM
if [ -f /etc/lightdm/lightdm.conf ]; then
    mkdir -p /etc/lightdm/lightdm.conf.d
    cat > /etc/lightdm/lightdm.conf.d/50-xoniant32.conf << EOF
[Seat:*]
autologin-user=$TARGET_USER
autologin-session=openbox
user-session=openbox
EOF
    info "LightDM configurado con Openbox por defecto."
fi

# SDDM
if [ -f /etc/sddm.conf ]; then
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/50-xoniant32.conf << EOF
[Autologin]
User=$TARGET_USER
Session=openbox.desktop

[Theme]
Current=breeze
EOF
    info "SDDM configurado con Openbox por defecto."
fi

# LXDM
if [ -f /etc/lxdm/lxdm.conf ]; then
    sed -i "s/^# autologin=.*/autologin=$TARGET_USER/" /etc/lxdm/lxdm.conf
    sed -i "s/^# session=.*/session=\/usr\/share\/xsessions\/openbox.desktop/" /etc/lxdm/lxdm.conf
    info "LXDM configurado con Openbox por defecto."
fi

# SLiM
if [ -f /etc/slim.conf ]; then
    echo "default_user $TARGET_USER" >> /etc/slim.conf
    echo "auto_login yes" >> /etc/slim.conf
    echo "session openbox" >> /etc/slim.conf
    info "SLiM configurado con Openbox por defecto."
fi

# Si no hay gestor de display (modo texto), configurar auto-login y startx
if ! pgrep -x "lightdm|sddm|lxdm|slim" >/dev/null 2>&1; then
    warn "No se detectó gestor de display. Se configurará auto-login en tty1 con startx automático."
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I 38400 linux
EOF
    # Añadir startx al .bashrc
    cat >> "$USER_HOME/.bashrc" << 'EOF'

# Iniciar X automáticamente en tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
    exit 0
fi
EOF
    info "Auto-login en consola configurado con startx automático."
fi

# ============================================
# 7. MENSAJE DE BIENVENIDA EN .bashrc
# ============================================
cat >> "$USER_HOME/.bashrc" << 'EOF'

# Mensaje de bienvenida
echo "========================================"
echo "   XONIANT32 - by Darian Alberto Camacho Salas"
echo "========================================"
echo "Comandos útiles:"
echo "  xoni-help     : Muestra esta ayuda"
echo "  xoni-menu     : Menú interactivo"
echo "  xoni-update   : Actualiza xoniant32"
echo "  xoni-install  : Instala herramientas XONI directamente en ~/"
echo "  sudo connmanctl : Configura la red WiFi"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"

# ============================================
# 8. CREAR SCRIPTS XONI
# ============================================
info "Creando scripts XONI..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
# xoni-install – Instalador de herramientas XONI directamente en ~/
# Autor: Darian Alberto Camacho Salas

REPO_BASE="https://github.com/XONIDU"
cd "$HOME"

if [ -n "$1" ]; then
    TOOL="$1"
    echo "Instalando $TOOL desde $REPO_BASE/$TOOL.git en ~/$TOOL ..."
    
    if [ -d "$TOOL" ]; then
        echo "Actualizando $TOOL existente..."
        cd "$TOOL" && git pull && cd ..
    else
        git clone "$REPO_BASE/$TOOL.git"
    fi
    
    # Buscar el archivo principal y crear enlace simbólico en /usr/local/bin
    if [ -f "$TOOL/start.py" ]; then
        echo "Creando enlace simbólico en /usr/local/bin/$TOOL (necesita sudo)"
        sudo ln -sf "$HOME/$TOOL/start.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible como comando global (enlace a ~/$TOOL/start.py)"
    elif [ -f "$TOOL/$TOOL.py" ]; then
        sudo ln -sf "$HOME/$TOOL/$TOOL.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible como comando global (enlace a ~/$TOOL/$TOOL.py)"
    elif [ -f "$TOOL/$TOOL.sh" ]; then
        sudo ln -sf "$HOME/$TOOL/$TOOL.sh" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL disponible como comando global (enlace a ~/$TOOL/$TOOL.sh)"
    else
        echo "[AVISO] No se encontró archivo principal, pero el repositorio está en ~/$TOOL"
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
# xoni-update – Actualiza xoniant32 y las herramientas XONI

# Actualizar scripts del sistema
REPO="https://github.com/XONIDU/xoniant32.git"
DIR="/opt/xoniant32"
echo "Actualizando scripts de xoniant32..."
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

# Actualizar herramientas en ~/
echo ""
echo "Actualizando herramientas en ~/ ..."
cd "$HOME"
for tool in */; do
    toolname="${tool%/}"
    if [ -d "$toolname" ] && [ -d "$toolname/.git" ]; then
        echo "Actualizando $toolname..."
        cd "$toolname" && git pull && cd "$HOME"
    fi
done

echo "[OK] xoniant32 actualizado"
EOF

cat > /usr/local/bin/xoni-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIANT32 - AYUDA
========================================
COMANDOS:
  xoni-help                    : Muestra esta ayuda
  xoni-menu                    : Menú interactivo
  xoni-update                  : Actualiza scripts y herramientas
  xoni-install <herramienta>   : Instala herramientas XONI en ~/

HERRAMIENTAS DISPONIBLES:
  xonitube, xonigraf, xonichat, xonimail, xonicar, xoniclus, xoniconver,
  xonidate, xonidal, xonidip, xoniencript, xonihelp, xonilab, xoniclient,
  xoniserver, xoniterm, xonifs, xonigrep, xonisearch, xonicrypt,
  xonidecode, xonicron, xonisync

ATAJOS:
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + u   : Actualizar
  Win + q   : Cerrar sesión

El sistema arranca directamente en modo gráfico con TERMINAL FIJA.
NO SE VE EL ESCRITORIO, solo la terminal maximizada sin bordes.
La terminal principal NO SE PUEDE CERRAR.

REPOSITORIO: https://github.com/XONIDU/xoniant32
HELP
EOF

cat > /usr/local/bin/xoni-menu << 'EOF'
#!/bin/bash
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
# 9. ACTUALIZAR MOTD
# ============================================
cat > /etc/motd << 'EOF'
========================================
   XONIANT32 - by Darian Alberto Camacho Salas
========================================
Comandos útiles:
  xoni-help     : Muestra esta ayuda
  xoni-menu     : Menú interactivo
  xoni-update   : Actualiza scripts y herramientas
  xoni-install  : Instala herramientas XONI directamente en ~/
  sudo connmanctl : Configura la red WiFi

El sistema arranca directamente en modo gráfico con TERMINAL FIJA.
NO SE VE EL ESCRITORIO, solo la terminal maximizada sin bordes.
La terminal principal NO SE PUEDE CERRAR.

Repositorio: https://github.com/XONIDU/xoniant32
========================================
EOF

# ============================================
# 10. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN COMPLETADA               "
echo "========================================"
echo ""
echo "Se ha configurado Openbox con terminal fija como inicio por defecto."
echo "Tras reiniciar, iniciarás sesión DIRECTAMENTE en la terminal."
echo "NO VERÁS EL ESCRITORIO, solo la terminal maximizada sin bordes."
echo "La terminal principal NO SE PUEDE CERRAR."
echo ""
echo "Para instalar xonitube: xoni-install xonitube"
echo ""
echo "Reinicia ahora: sudo reboot"
echo ""
echo "Usuario: $TARGET_USER"
echo ""
echo "¡Disfruta xoniant32!"
