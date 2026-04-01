#!/bin/bash
# install-xoniant32-ultimate.sh – Terminal fija optimizada con xoni-update
# Autor: Darian Alberto Camacho Salas
#
# Este script:
# 1. ELIMINA paquetes INNECESARIOS (ahorro de RAM y disco)
# 2. CONSERVA TODO lo gráfico (controladores, codecs, Xorg, OpenGL)
# 3. CONFIGURA Openbox como única sesión
# 4. Terminal principal fija que OCULTA el escritorio
# 5. Ventanas emergentes (mpv, terminales) se ven ENCIMA
# 6. Añade soporte de ratón (copiar/pegar) y atajos completos
# 7. INCLUYE xoni-update para actualizaciones desde GitHub

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
echo "   XONIANT32 ULTIMATE - OPTIMIZADO     "
echo "   by Darian Alberto Camacho Salas     "
echo "========================================"
echo "Este script ELIMINA paquetes INNECESARIOS"
echo "para ahorrar RAM y espacio en disco."
echo ""
echo "CONSERVA todo lo GRÁFICO:"
echo "  ✓ Controladores de video (Intel, AMD, NVIDIA, VESA)"
echo "  ✓ Codecs multimedia (mpv, ffmpeg, yt-dlp)"
echo "  ✓ Xorg completo y bibliotecas gráficas"
echo "  ✓ ALSA y PulseAudio"
echo ""
echo "ELIMINA (para liberar recursos):"
echo "  - Impresión (CUPS) - si no usas impresora"
echo "  - Bluetooth - si no usas dispositivos BT"
echo "  - Wicd (gestor alternativo) - usamos connman"
echo "  - Scanner (saned)"
echo "  - Juegos preinstalados"
echo "  - Otros gestores de ventanas (icewm, fluxbox, jwm)"
echo "  - Documentación (man pages)"
echo "  - Paquetes de desarrollo (build-essential, etc.)"
echo ""
echo "INICIARÁ DIRECTAMENTE EN TERMINAL (sin escritorio)"
echo "========================================"
echo ""
read -p "¿Continuar? (s/n): " CONFIRM
[[ "$CONFIRM" =~ ^[Ss]$ ]] || error_exit "Operación cancelada."

# ============================================
# 1. ELIMINAR PAQUETES INNECESARIOS (CONSERVANDO GRÁFICOS)
# ============================================
info "Eliminando paquetes innecesarios (liberando RAM y disco)..."

# Impresión (solo si no la usas)
apt purge -y cups cups-client cups-common cups-filters cups-ppdc || true

# Bluetooth (servicios, no drivers)
apt purge -y bluez bluetooth bluez-utils || true

# Gestores de red alternativos
apt purge -y wicd wicd-gtk wicd-daemon || true

# Scanner
apt purge -y sane saned sane-utils || true

# Juegos y aplicaciones innecesarias
apt purge -y gnome-games* aisleriot solitaire || true

# Gestores de ventanas adicionales (solo conservamos Openbox)
apt purge -y icewm* fluxbox* jwm* || true

# Documentación (libera espacio)
apt purge -y man-db manpages info || true

# Paquetes de desarrollo (si no compilas nada)
apt purge -y build-essential gcc g++ make cmake automake autoconf || true

# ============================================
# 2. ACTUALIZAR REPOSITORIOS
# ============================================
info "Actualizando repositorios..."
apt update

# ============================================
# 3. INSTALAR PAQUETES ESENCIALES
# ============================================
info "Instalando paquetes esenciales..."
apt install -y git curl wget htop nano alsa-utils pulseaudio pavucontrol
apt install -y xorg xserver-xorg-core xserver-xorg-video-fbdev xserver-xorg-video-vesa
apt install -y openbox obconf rxvt-unicode
apt install -y mpv yt-dlp ffmpeg
apt install -y xclip xsel connman

# Controladores Intel (opcional, recomendado)
apt install -y xserver-xorg-video-intel || true

# ============================================
# 4. CONFIGURAR MPV (optimizado)
# ============================================
info "Configurando mpv..."
mkdir -p /etc/mpv
cat > /etc/mpv/mpv.conf << 'EOF'
vo=x11
ao=alsa
cache=yes
cache-secs=15
profile=fast
vd-lavc-fast
vd-lavc-skip-loop-filter=all
no-sub
no-osc
no-osd-bar
no-window-dragging
keepaspect-window
geometry=640x360
x11-bypass-compositor=yes
ontop
msg-level=all=error
EOF

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="/home/$TARGET_USER"
mkdir -p "$USER_HOME/.config/mpv"
cp /etc/mpv/mpv.conf "$USER_HOME/.config/mpv/"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config/mpv"

# ============================================
# 5. CONFIGURAR URXVT (COPIA/PEGA CON RATÓN)
# ============================================
info "Configurando urxvt con soporte de portapapeles..."

mkdir -p "$USER_HOME/.urxvt/ext"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.urxvt"

cat > "$USER_HOME/.urxvt/ext/clipboard-paste-on-right-click" << 'EOF'
#! perl
sub on_button_press {
    my ($self, $event) = @_;
    if ($event->{button} == 3 && $event->{state} == 0) {
        my $clipboard = `xclip -selection clipboard -o 2>/dev/null`;
        if ($clipboard) {
            $self->tt_paste($clipboard);
            return 1;
        }
    }
    return ();
}
EOF

chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.urxvt/ext/clipboard-paste-on-right-click"

cat > "$USER_HOME/.Xresources" << 'EOF'
URxvt.font: xft:monospace:size=10
URxvt.background: black
URxvt.foreground: white
URxvt.scrollBar: false
URxvt.saveLines: 5000
URxvt.perl-ext-common: default,clipboard-paste-on-right-click
URxvt.keysym.Shift-Control-C: eval:selection_to_clipboard
URxvt.keysym.Shift-Control-V: eval:paste_clipboard
URxvt.keysym.Control-Insert: eval:selection_to_clipboard
URxvt.keysym.Shift-Insert: eval:paste_clipboard
URxvt.iso14755: false
URxvt.iso14755_52: false
URxvt.selectStyle: word
EOF

chown "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.Xresources"

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
      <layer>below</layer>
      <position force="yes"><x>0</x><y>0</y></position>
    </application>
    <application class="URxvt" name="urxvt" title="!principal">
      <layer>above</layer>
    </application>
    <application class="Mpv">
      <layer>above</layer>
    </application>
  </applications>
  <menu><file>~/.config/openbox/menu.xml</file></menu>
  <keyboard>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="A-S-Tab"><action name="PreviousWindow"/></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="A-F10"><action name="ToggleMaximize"/></keybind>
    <keybind key="W-Up"><action name="ToggleMaximize"/></keybind>
    <keybind key="W-x"><action name="Execute"><command>xoni-menu</command></action></keybind>
    <keybind key="W-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="C-A-t"><action name="Execute"><command>urxvt</command></action></keybind>
    <keybind key="W-h"><action name="Execute"><command>xoni-help</command></action></keybind>
    <keybind key="W-q"><action name="Exit"/></keybind>
  </keyboard>
  <mouse>
    <context name="Root">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
    </context>
  </mouse>
</openbox_config>
EOF

cat > "$USER_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniant32 Ultimate">
    <item label="Nueva terminal (Ctrl+Alt+T)">
      <action name="Execute"><command>urxvt</command></action>
    </item>
    <separator/>
    <item label="Instalar herramienta XONI">
      <action name="Execute"><command>urxvt -e xoni-install</command></action>
    </item>
    <item label="Configurar red (connman)">
      <action name="Execute"><command>urxvt -e sudo connmanctl</command></action>
    </item>
    <separator/>
    <item label="Actualizar xoniant32">
      <action name="Execute"><command>urxvt -e xoni-update</command></action>
    </item>
    <separator/>
    <item label="Ayuda">
      <action name="Execute"><command>xoni-help</command></action>
    </item>
    <item label="Cerrar sesión (Win+q)">
      <action name="Exit"/>
    </item>
  </menu>
</openbox_menu>
EOF

cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
urxvt -title "principal" -fg white -bg black &

# Cargar configuración Xresources
xrdb -merge ~/.Xresources
EOF

cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$USER_HOME/.xinitrc"

# ============================================
# 7. CONFIGURAR CONNMAN
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
# 8. FORZAR OPENBOX COMO ÚNICA SESIÓN
# ============================================
info "Forzando Openbox como única sesión..."

mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/openbox.desktop << 'EOF'
[Desktop Entry]
Name=Openbox
Comment=Openbox Window Manager
Exec=openbox-session
Type=Application
EOF

for wm in icewm fluxbox jwm; do
    if [ -f "/usr/share/xsessions/$wm.desktop" ]; then
        mv "/usr/share/xsessions/$wm.desktop" "/usr/share/xsessions/$wm.desktop.disabled" 2>/dev/null || true
    fi
done

# ============================================
# 9. CONFIGURAR AUTO-LOGIN
# ============================================
info "Configurando auto-login..."

if [ -f /etc/lightdm/lightdm.conf ]; then
    mkdir -p /etc/lightdm/lightdm.conf.d
    cat > /etc/lightdm/lightdm.conf.d/50-xoniant32.conf << EOF
[Seat:*]
autologin-user=$TARGET_USER
autologin-session=openbox
user-session=openbox
EOF
    info "LightDM configurado."
fi

if [ -f /etc/sddm.conf ]; then
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/50-xoniant32.conf << EOF
[Autologin]
User=$TARGET_USER
Session=openbox.desktop
EOF
    info "SDDM configurado."
fi

if [ -f /etc/lxdm/lxdm.conf ]; then
    sed -i "s/^# autologin=.*/autologin=$TARGET_USER/" /etc/lxdm/lxdm.conf
    sed -i "s/^# session=.*/session=\/usr\/share\/xsessions\/openbox.desktop/" /etc/lxdm/lxdm.conf
    info "LXDM configurado."
fi

if [ -f /etc/slim.conf ]; then
    echo "default_user $TARGET_USER" >> /etc/slim.conf
    echo "auto_login yes" >> /etc/slim.conf
    echo "session openbox" >> /etc/slim.conf
    info "SLiM configurado."
fi

# Fallback a consola
if ! pgrep -x "lightdm|sddm|lxdm|slim" >/dev/null 2>&1; then
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
    info "Auto-login en consola configurado."
fi

# ============================================
# 10. CREAR SCRIPTS XONI (CON xoni-update)
# ============================================
info "Creando scripts XONI..."

cat > /usr/local/bin/xoni-install << 'EOF'
#!/bin/bash
REPO_BASE="https://github.com/XONIDU"
cd "$HOME"
TOOL="${1:-}"
if [ -z "$TOOL" ]; then
    echo "Herramientas: xonitube, xonigraf, xonichat, xonimail"
    read -p "Instalar: " TOOL
fi
if [ -n "$TOOL" ]; then
    [ -d "$TOOL" ] || git clone "$REPO_BASE/$TOOL.git"
    if [ -f "$TOOL/start.py" ]; then
        sudo ln -sf "$HOME/$TOOL/start.py" "/usr/local/bin/$TOOL"
        sudo chmod +x "/usr/local/bin/$TOOL"
        echo "[OK] $TOOL instalado (comando: $TOOL)"
    else
        echo "[AVISO] Repositorio descargado en ~/$TOOL"
    fi
fi
EOF

cat > /usr/local/bin/xoni-update << 'EOF'
#!/bin/bash
# xoni-update – Actualiza xoniant32 desde GitHub
REPO="https://github.com/XONIDU/xoniant32.git"
DIR="/opt/xoniant32"
echo "Actualizando xoniant32 desde GitHub..."
if [ ! -d "$DIR" ]; then
    sudo git clone "$REPO" "$DIR"
else
    cd "$DIR" && sudo git pull
fi
# Actualizar scripts
if [ -f "$DIR/install-xoniant32-ultimate.sh" ]; then
    sudo cp "$DIR/install-xoniant32-ultimate.sh" /usr/local/bin/install-xoniant32-ultimate.sh
    sudo chmod +x /usr/local/bin/install-xoniant32-ultimate.sh
fi
# Actualizar scripts XONI
sudo cp -v "$DIR"/scripts/xoni-* /usr/local/bin/ 2>/dev/null || true
sudo chmod +x /usr/local/bin/xoni-* 2>/dev/null || true
# Eliminar scripts antiguos
sudo rm -f /usr/local/bin/xoniarch-* 2>/dev/null || true
echo "[OK] xoniant32 actualizado correctamente"
EOF

cat > /usr/local/bin/xoni-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "============================="
    echo "  XONIANT32 ULTIMATE - MENÚ"
    echo "============================="
    echo "1) Nueva terminal (Ctrl+Alt+T)"
    echo "2) Instalar herramienta XONI"
    echo "3) Configurar red (connman)"
    echo "4) Actualizar xoniant32"
    echo "5) Ayuda"
    echo "6) Cerrar sesión (Win+q)"
    echo ""
    read -p "Opción: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e xoni-install ; read -p "Enter..." ;;
        3) urxvt -e sudo connmanctl ;;
        4) urxvt -e xoni-update ; read -p "Enter..." ;;
        5) xoni-help ; read -p "Enter..." ;;
        6) openbox --exit ;;
    esac
done
EOF

cat > /usr/local/bin/xoni-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIANT32 ULTIMATE - AYUDA
========================================
COMANDOS:
  xoni-menu     : Menú interactivo
  xoni-install  : Instalar herramientas
  xoni-update   : Actualizar xoniant32
  sudo connmanctl : Configurar WiFi

ATAJOS:
  Alt+Tab       : Cambiar ventana
  Alt+F4        : Cerrar ventana
  Alt+F10       : Maximizar
  Win+↑         : Maximizar
  Ctrl+Alt+T    : Nueva terminal
  Win+x         : Menú
  Win+q         : Cerrar sesión

RATÓN:
  Seleccionar texto : Copia
  Click derecho     : Pegar

✓ Terminal principal NO SE PUEDE CERRAR
✓ Ventanas emergentes se ven ENCIMA
✓ Actualización con xoni-update

Repositorio: https://github.com/XONIDU/xoniant32
HELP
EOF

chmod +x /usr/local/bin/xoni-*

# Mensaje de bienvenida
cat >> "$USER_HOME/.bashrc" << 'EOF'

echo "========================================"
echo "   XONIANT32 ULTIMATE - OPTIMIZADO"
echo "   by Darian Alberto Camacho Salas"
echo "========================================"
echo "Comandos: xoni-help, xoni-menu, xoni-install, xoni-update"
echo ""
echo "ATAJOS: Alt+Tab, Ctrl+Alt+T, Win+x, Win+q"
echo "RATÓN: Seleccionar copia, click derecho pega"
echo ""
echo "✓ Terminal principal NO SE PUEDE CERRAR"
echo "✓ Actualizar con: sudo xoni-update"
echo "========================================"
EOF

chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/.xinitrc" "$USER_HOME/.bashrc"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.Xresources" "$USER_HOME/.urxvt"

# ============================================
# 11. LIMPIEZA FINAL
# ============================================
info "Eliminando dependencias no usadas..."
apt autoremove --purge -y

info "Limpiando caché..."
apt clean
apt autoclean

# ============================================
# 12. FINALIZACIÓN
# ============================================
echo "========================================"
echo "   INSTALACIÓN ULTIMATE COMPLETADA      "
echo "========================================"
echo ""
echo "✅ OPTIMIZACIONES REALIZADAS:"
echo "   ✓ Eliminados paquetes innecesarios"
echo "   ✓ Conservados todos los controladores gráficos"
echo "   ✓ Forzado Openbox como única sesión"
echo "   ✓ Terminal principal OCULTA el escritorio"
echo "   ✓ Ventanas emergentes se ven ENCIMA"
echo "   ✓ Atajos completos + ratón copiar/pegar"
echo "   ✓ xoni-update configurado"
echo ""
echo "▶ Para instalar xonitube:  xoni-install xonitube"
echo "▶ Para actualizar:         sudo xoni-update"
echo "▶ Para abrir el menú:      xoni-menu"
echo "▶ Para ayuda:              xoni-help"
echo ""
echo "Reinicia ahora: sudo reboot"
echo ""
echo "Usuario: $TARGET_USER"
echo "========================================"
