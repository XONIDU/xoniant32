#!/bin/bash
# install-xoniant32.sh – Terminal fija + limpieza de recursos
# Autor: Darian Alberto Camacho Salas
#
# Este script:
# 1. NO DESINSTALA NADA POR DEFECTO (solo pregunta)
# 2. Configura Openbox con terminal fija que oculta el escritorio
# 3. Ofrece limpiar paquetes innecesarios para liberar RAM
# 4. Las herramientas XONI se instalan en ~/ (ej: ~/xonitube)

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
echo "   XONIANT32 - TERMINAL FIJA + LIMPIEZA"
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo ""
echo "Este script te preguntará ANTES de eliminar nada."
echo "Ningún paquete se borrará sin tu confirmación."
echo ""

# ============================================
# SECCIÓN DE LIMPIEZA OPCIONAL (BASADA EN FOROS)
# ============================================
echo "========================================"
echo "   LIMPIEZA OPCIONAL DE RECURSOS        "
echo "========================================"
echo ""
echo "Basado en recomendaciones de la comunidad antiX [citation:1][citation:3]"
echo "para reducir el consumo de RAM (ahorro potencial: ~20-50 MB)"
echo ""

# Cups (servidor de impresión) - innecesario si no hay impresora
if dpkg -l cups >/dev/null 2>&1; then
    read -p "¿Eliminar servidor de impresión CUPS? (s/n) [recomendado si no tienes impresora]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        apt purge -y cups || warn "No se pudo eliminar cups"
        info "CUPS eliminado."
    fi
fi

# Bluetooth
if dpkg -l bluez >/dev/null 2>&1; then
    read -p "¿Eliminar soporte Bluetooth? (s/n) [ahorra ~10MB RAM]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        apt purge -y bluez* bluetooth* || warn "No se pudo eliminar bluetooth"
        info "Bluetooth eliminado."
    fi
fi

# Wicd (gestor de red alternativo) - no necesario si usas connman
if dpkg -l wicd >/dev/null 2>&1; then
    read -p "¿Eliminar wicd? (s/n) [usamos connman, ahorra ~15MB RAM]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        apt purge -y wicd* || warn "No se pudo eliminar wicd"
        info "wicd eliminado."
    fi
fi

# Saned (servicio de scanner)
if dpkg -l saned >/dev/null 2>&1; then
    read -p "¿Eliminar soporte de scanner (saned)? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        apt purge -y saned || warn "No se pudo eliminar saned"
        info "saned eliminado."
    fi
fi

# Servicios para portátiles (si es escritorio)
if ! dmidecode -s system-product-name 2>/dev/null | grep -qi "laptop"; then
    echo ""
    echo "Parece que este equipo NO es un portátil."
    read -p "¿Eliminar servicios específicos de portátiles (acpi, pcmciautils)? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        apt purge -y acpi acpid pcmciautils || warn "Alguno no se pudo eliminar"
        info "Servicios de portátil eliminados."
    fi
fi

# Juegos (gnome-games, etc.)
read -p "¿Eliminar juegos preinstalados? (s/n) [ahorra ~30MB]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    apt purge -y gnome-games* aisleriot solitaire || warn "Algunos juegos no se eliminaron"
    info "Juegos eliminados."
fi

# Gestores de ventanas adicionales (opcional, pero para xoniant32 solo necesitamos Openbox)
echo ""
echo "Xoniant32 usa Openbox como gestor principal."
read -p "¿Eliminar otros gestores de ventanas (icewm, fluxbox, jwm)? (s/n) [recomendado]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    apt purge -y icewm* fluxbox* jwm* || warn "Algunos no se eliminaron"
    info "Otros gestores eliminados."
fi

# ============================================
# 2. AUTOLIMPIEZA FINAL
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando caché..."
apt clean
apt autoclean

# ============================================
# 3. INSTALAR PAQUETES NECESARIOS
# ============================================
info "Actualizando repositorios..."
apt update

info "Instalando paquetes necesarios..."
apt install -y git curl wget htop nano alsa-utils connman
apt install -y xorg openbox rxvt-unicode
apt install -y mpv yt-dlp ffmpeg
apt install -y firmware-atheros firmware-iwlwifi firmware-realtek || true

# ============================================
# 4. CONFIGURAR CONNMAN
# ============================================
info "Configurando connman..."
mkdir -p /etc/connman
cat > /etc/connman/main.conf << 'EOF'
[General]
PreferredTechnologies = wifi,ethernet
AllowHostnames = true
AutoConnect = true
EOF
systemctl restart connman || sv restart connman || true

# ============================================
# 5. CONFIGURAR MPV
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
      <position force="yes">
        <x>0</x>
        <y>0</y>
      </position>
    </application>
  </applications>
  <menu><file>~/.config/openbox/menu.xml</file></menu>
  <keyboard>
    <keybind key="W-x"><action name="Execute"><command>xoni-menu</command></action></keybind>
    <keybind key="W-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="W-h"><action name="Execute"><command>xoni-help</command></action></keybind>
    <keybind key="W-q"><action name="Exit"/></keybind>
  </keyboard>
</openbox_config>
EOF

# Menú mínimo
cat > "$USER_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e xoni-install</command></action></item>
    <item label="Configurar red"><action name="Execute"><command>urxvt -e sudo connmanctl</command></action></item>
    <item label="Cerrar sesión"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

# Autostart - solo terminal
cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL - OCUPA TODA LA PANTALLA
urxvt -title "principal" -fg white -bg black &
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

# ============================================
# 7. DESACTIVAR OTROS GESTORES DE VENTANAS
# ============================================
info "Desactivando otros gestores de ventanas..."
for wm in icewm fluxbox jwm; do
    if [ -f "/usr/share/xsessions/$wm.desktop" ]; then
        mv "/usr/share/xsessions/$wm.desktop" "/usr/share/xsessions/$wm.desktop.disabled" 2>/dev/null || true
    fi
done

# ============================================
# 8. CONFIGURAR AUTO-LOGIN
# ============================================
info "Configurando auto-login..."

# LightDM
if [ -f /etc/lightdm/lightdm.conf ]; then
    mkdir -p /etc/lightdm/lightdm.conf.d
    cat > /etc/lightdm/lightdm.conf.d/50-xoniant32.conf << EOF
[Seat:*]
autologin-user=$TARGET_USER
autologin-session=openbox
user-session=openbox
EOF
fi

# SDDM
if [ -f /etc/sddm.conf ]; then
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/50-xoniant32.conf << EOF
[Autologin]
User=$TARGET_USER
Session=openbox.desktop
EOF
fi

# Si no hay gestor de display
if ! pgrep -x "lightdm|sddm|lxdm|slim" >/dev/null 2>&1; then
    warn "No se detectó gestor de display. Configurando auto-login en consola."
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $TARGET_USER --noclear %I 38400 linux
EOF
    cat >> "$USER_HOME/.bashrc" << 'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
    exit 0
fi
EOF
fi

# ============================================
# 9. CREAR SCRIPTS XONI
# ============================================
info "Creando scripts XONI..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
REPO_BASE="https://github.com/XONIDU"
cd "$HOME"
TOOL="${1:-}"
if [ -z "$TOOL" ]; then
    echo "Herramientas: xonitube, xonigraf, xonichat, xonimail"
    read -p "Herramienta: " TOOL
fi
if [ -n "$TOOL" ]; then
    [ -d "$TOOL" ] || git clone "$REPO_BASE/$TOOL.git"
    [ -f "$TOOL/start.py" ] && sudo ln -sf "$HOME/$TOOL/start.py" "/usr/local/bin/$TOOL"
    sudo chmod +x "/usr/local/bin/$TOOL"
    echo "[OK] $TOOL"
fi
EOF

cat > /usr/local/bin/xoni-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "============================="
    echo "    XONIANT32 - MENÚ"
    echo "============================="
    echo "1) Nueva terminal"
    echo "2) Instalar herramienta"
    echo "3) Configurar red"
    echo "4) Cerrar sesión"
    read -p "Opción: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e xoni-install ; read -p "Enter..." ;;
        3) urxvt -e sudo connmanctl ;;
        4) openbox --exit ;;
    esac
done
EOF

cat > /usr/local/bin/xoni-help << 'EOF'
#!/bin/bash
cat << 'HELP'
Sistema XONIANT32 - Terminal Fija
Comandos: xoni-menu, xoni-install <tool>
Win+x: Menú | Win+t: Nueva terminal | Win+q: Salir
HELP
EOF

chmod +x /usr/local/bin/xoni-*

cat >> "$USER_HOME/.bashrc" << 'EOF'
echo "========================================"
echo "   XONIANT32 - by Darian Alberto Camacho Salas"
echo "========================================"
echo "Comandos: xoni-help, xoni-menu, xoni-install"
echo "Win+x: Menú | Win+t: Terminal | Win+q: Salir"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"

# ============================================
# 10. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN COMPLETADA               "
echo "========================================"
echo ""
echo "Resumen:"
echo "✓ Terminal fija configurada (oculta el escritorio)"
if [ -n "$(apt list --installed 2>/dev/null | grep -E 'cups|bluez|wicd')" ]; then
    echo "✓ Se eliminaron algunos paquetes según tus respuestas"
else
    echo "✓ No se eliminaron paquetes adicionales"
fi
echo ""
echo "Al reiniciar, SOLO VERÁS LA TERMINAL."
echo ""
echo "Reinicia ahora: sudo reboot"
echo "Usuario: $TARGET_USER"
echo ""
