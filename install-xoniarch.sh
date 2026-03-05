#!/bin/bash
# XONIARCH32 - INSTALADOR BASE COMPLETO
# Ejecutar DESPUES de instalar Arch Linux base
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/xonidu/xoniarch32

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   XONIARCH32 - INSTALADOR BASE        ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}GRAFICO SIEMPRE ACTIVO${NC}"
echo -e "${YELLOW}Las herramientas XONI se instalan con: installxoni <herramienta>${NC}"
echo -e "${GREEN}========================================${NC}"

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor ejecuta como root (sudo)${NC}"
    exit 1
fi

# Obtener nombre de usuario real
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME="/home/$REAL_USER"

# ============================================
# PASO 1: ACTUALIZAR SISTEMA BASE
# ============================================
echo -e "${YELLOW}[1/12] Actualizando sistema base...${NC}"
pacman -Syu --noconfirm

# ============================================
# PASO 2: INSTALAR PAQUETES ESENCIALES
# ============================================
echo -e "${YELLOW}[2/12] Instalando paquetes esenciales...${NC}"
pacman -S --noconfirm \
    base-devel \
    linux-headers \
    git \
    wget \
    curl \
    nano \
    vim \
    htop \
    neofetch \
    sudo \
    openssh \
    rsync \
    unzip \
    zip \
    p7zip \
    ntfs-3g \
    dosfstools \
    exfat-utils \
    networkmanager \
    network-manager-applet \
    wpa_supplicant \
    dialog \
    wireless_tools \
    nmtui \
    acpi \
    acpid \
    tlp \
    tlp-rdw \
    lm_sensors \
    parted \
    gptfdisk \
    fdisk \
    gparted \
    arch-install-scripts

# ============================================
# PASO 3: SOPORTE DE AUDIO COMPLETO
# ============================================
echo -e "${YELLOW}[3/12] Instalando soporte de audio...${NC}"
pacman -S --noconfirm \
    alsa-utils \
    alsa-firmware \
    alsa-plugins \
    pulseaudio \
    pulseaudio-alsa \
    pulseaudio-bluetooth \
    pavucontrol \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber

# ============================================
# PASO 4: SOPORTE DE VIDEO COMPLETO
# ============================================
echo -e "${YELLOW}[4/12] Instalando controladores de video...${NC}"
pacman -S --noconfirm \
    xf86-video-intel \
    xf86-video-ati \
    xf86-video-amdgpu \
    xf86-video-nouveau \
    xf86-video-vesa \
    xf86-video-fbdev \
    xf86-video-vmware \
    xf86-video-qxl \
    xf86-video-openchrome \
    mesa \
    mesa-demos \
    vulkan-intel \
    vulkan-radeon \
    vulkan-mesa-layer \
    libva-intel-driver \
    libva-mesa-driver \
    libva-utils

# ============================================
# PASO 5: INSTALAR XORG Y OPENBOX
# ============================================
echo -e "${YELLOW}[5/12] Instalando Xorg y Openbox...${NC}"
pacman -S --noconfirm \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xorg-xinput \
    xorg-xauth \
    xorg-xmodmap \
    xorg-xrdb \
    xorg-xset \
    xorg-xsetroot \
    xterm \
    openbox \
    obconf \
    tint2 \
    feh \
    picom \
    nitrogen \
    lxappearance \
    arandr

# ============================================
# PASO 6: TERMINALES Y HERRAMIENTAS GRAFICAS
# ============================================
echo -e "${YELLOW}[6/12] Instalando terminales y herramientas...${NC}"
pacman -S --noconfirm \
    rxvt-unicode \
    urxvt-perls \
    xfce4-terminal \
    pcmanfm \
    ranger \
    geany \
    mousepad \
    galculator \
    viewnior \
    ristretto \
    evince \
    firefox \
    mpv \
    vlc \
    ffmpeg \
    yt-dlp

# ============================================
# PASO 7: INSTALAR SDDM PARA LOGIN GRAFICO AUTOMATICO
# ============================================
echo -e "${YELLOW}[7/12] Instalando gestor de login grafico...${NC}"
pacman -S --noconfirm sddm sddm-kcm

# Configurar SDDM para login automatico
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$REAL_USER
Session=openbox.desktop

[Theme]
Current=breeze
EOF

# Habilitar SDDM
systemctl enable sddm

# ============================================
# PASO 8: CREAR CONFIGURACION DE TERMINAL FIJA
# ============================================
echo -e "${YELLOW}[8/12] Configurando terminal fija...${NC}"

# Crear directorios de configuracion
mkdir -p "$REAL_HOME/.config/openbox"
mkdir -p "$REAL_HOME/.config/tint2"
mkdir -p "$REAL_HOME/.local/bin"
mkdir -p /usr/share/xsessions
mkdir -p /usr/local/bin
mkdir -p /opt/xoniarch/bin

# Configuracion de Openbox - TERMINAL FIJA (no se puede cerrar)
cat > "$REAL_HOME/.config/openbox/rc.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config>
  <applications>
    <application class="URxvt" name="urxvt" title="principal">
      <decor>no</decor>
      <maximized>yes</maximized>
      <focus>yes</focus>
      <desktop>all</desktop>
      <layer>above</layer>
      <skip_taskbar>no</skip_taskbar>
      <skip_pager>no</skip_pager>
    </application>
  </applications>
  
  <menu>
    <file>~/.config/openbox/menu.xml</file>
  </menu>
  
  <keyboard>
    <keybind key="W-x">
      <action name="Execute"><command>xoniarch-menu</command></action>
    </keybind>
    <keybind key="W-t">
      <action name="Execute"><command>urxvt</command></action>
    </keybind>
    <keybind key="W-h">
      <action name="Execute"><command>xoniarch-help</command></action>
    </keybind>
    <keybind key="W-i">
      <action name="Execute"><command>installxoni</command></action>
    </keybind>
    <keybind key="W-q">
      <action name="Exit"/>
    </keybind>
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

# Menu de Openbox
cat > "$REAL_HOME/.config/openbox/menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniarch32">
    <item label="Nueva terminal">
      <action name="Execute"><command>urxvt</command></action>
    </item>
    <separator/>
    <item label="Instalar herramienta XONI">
      <action name="Execute"><command>urxvt -e installxoni</command></action>
    </item>
    <item label="Ver herramientas instaladas">
      <action name="Execute"><command>urxvt -e ls /opt/xoniarch</command></action>
    </item>
    <separator/>
    <item label="Configurar red (nmtui)">
      <action name="Execute"><command>urxvt -e nmtui</command></action>
    </item>
    <item label="Monitor del sistema">
      <action name="Execute"><command>urxvt -e htop</command></action>
    </item>
    <item label="Gestor de archivos">
      <action name="Execute"><command>pcmanfm</command></action>
    </item>
    <separator/>
    <item label="Ayuda">
      <action name="Execute"><command>urxvt -e xoniarch-help</command></action>
    </item>
    <item label="Cerrar sesion">
      <action name="Exit"/>
    </item>
  </menu>
</openbox_menu>
EOF

# Autostart - LANZA LA TERMINAL PRINCIPAL
cat > "$REAL_HOME/.config/openbox/autostart" << 'EOF'
#!/bin/bash

# Configurar pantalla
xrandr --output $(xrandr | grep " connected" | head -1 | cut -d" " -f1) --mode 1024x768 --rate 60 2>/dev/null || true

# Fondo de pantalla
feh --bg-scale /usr/share/backgrounds/default.jpg 2>/dev/null &

# Compositor para transparencias
picom -b 2>/dev/null &

# Barra de tareas
tint2 &

# TERMINAL PRINCIPAL (NO SE PUEDE CERRAR)
(sleep 2 && urxvt -title "principal") &

# Desactivar ahorro de energia
xset s off
xset -dpms
EOF
chmod +x "$REAL_HOME/.config/openbox/autostart"

# Configuracion de tint2
cat > "$REAL_HOME/.config/tint2/tint2rc" << 'EOF'
# Tint2 config
panel_items = LTSC
panel_size = 100% 30
panel_margin = 0 0
panel_padding = 2 2
font_shadow = 0
mouse_effects = 1
font = Sans 9
background_color = #000000 80
taskbar_mode = multi_desktop
task_icon = 1
task_text = 0
clock_format = %H:%M
clock_font = Sans 9
EOF

# .xinitrc (por si acaso)
cat > "$REAL_HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec openbox-session
EOF
chmod +x "$REAL_HOME/.xinitrc"

# Sesion de Openbox para SDDM
cat > /usr/share/xsessions/openbox.desktop << 'EOF'
[Desktop Entry]
Name=Openbox
Comment=Openbox Window Manager
Exec=openbox-session
Type=Application
EOF

# ============================================
# PASO 9: CREAR INSTALADOR DE HERRAMIENTAS XONI
# ============================================
echo -e "${YELLOW}[9/12] Creando instalador de herramientas XONI...${NC}"

cat > /usr/local/bin/installxoni << 'EOF'
#!/bin/bash
# Instalador de herramientas XONI desde GitHub

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "========================================"
echo "   INSTALADOR DE HERRAMIENTAS XONI"
echo "========================================"
echo ""

# Lista de herramientas disponibles
echo -e "${YELLOW}Herramientas disponibles:${NC}"
echo "  xoniarch32  - Nucleo del sistema"
echo "  xonitube    - Buscador de YouTube"
echo "  xonigraf    - Graficador matematico"
echo "  xonichat    - Chat con IA"
echo "  xonimail    - Cliente de correo"
echo "  xonicar     - Herramienta de vehiculos"
echo "  xoniclus    - Utilidad de clusters"
echo "  xoniconver  - Conversor de formatos"
echo "  xonidate    - Gestor de fechas"
echo "  xonidal     - Utilidad DAL"
echo "  xonidip     - Herramienta DIP"
echo "  xoniencript - Encriptador"
echo "  xonihelp    - Ayuda por comandos"
echo "  xonilab     - Laboratorio"
echo "  xoniclient  - Cliente de red"
echo "  xoniserver  - Servidor"
echo "  xoniterm    - Terminal mejorada"
echo "  xonifs      - Sistema de archivos"
echo "  xonigrep    - Buscador de texto"
echo "  xonisearch  - Buscador general"
echo "  xonicrypt   - Criptografia"
echo "  xonidecode  - Decodificador"
echo "  xonicron    - Gestor de tareas"
echo "  xonisync    - Sincronizador"
echo ""

if [ -z "$1" ]; then
    read -p "Nombre de la herramienta a instalar: " TOOL
else
    TOOL=$1
fi

if [ -z "$TOOL" ]; then
    echo -e "${RED}No se especifico ninguna herramienta${NC}"
    exit 1
fi

echo -e "${YELLOW}Instalando $TOOL...${NC}"

# Crear directorio si no existe
mkdir -p /opt/xoniarch
cd /opt/xoniarch

if [ -d "$TOOL" ]; then
    echo "Actualizando $TOOL existente..."
    cd "$TOOL"
    git pull
    cd ..
else
    echo "Clonando https://github.com/XONIDU/$TOOL.git"
    git clone "https://github.com/XONIDU/$TOOL.git" 2>/dev/null || {
        echo -e "${RED}Error: No se pudo clonar $TOOL${NC}"
        exit 1
    }
fi

# Hacer ejecutables los scripts
find "$TOOL" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
find "$TOOL" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Crear enlaces simbolicos
for script in $(find "$TOOL" -maxdepth 2 -name "*.py" -o -name "*.sh" 2>/dev/null | grep -v "__" | head -5); do
    if [ -f "$script" ]; then
        base=$(basename "$script" .py)
        base=$(basename "$base" .sh)
        ln -sf "$(pwd)/$script" "/opt/xoniarch/bin/$base" 2>/dev/null || true
        ln -sf "/opt/xoniarch/bin/$base" "/usr/local/bin/$base" 2>/dev/null || true
    fi
done

echo -e "${GREEN}$TOOL instalado correctamente${NC}"
echo "Ejecuta: $TOOL (desde cualquier terminal)"
EOF
chmod +x /usr/local/bin/installxoni

# ============================================
# PASO 10: CREAR SCRIPTS PRINCIPALES
# ============================================
echo -e "${YELLOW}[10/12] Creando scripts principales...${NC}"

# xoniarch-help
cat > /usr/local/bin/xoniarch-help << 'EOF'
#!/bin/bash
cat << 'EOT'
========================================
   XONIARCH32 - AYUDA
========================================

COMANDOS PRINCIPALES:
  installxoni <herramienta> : Instalar herramienta XONI
  xoniarch-help             : Mostrar esta ayuda
  xoniarch-menu             : Menu interactivo

EJEMPLOS:
  installxoni xonitube      : Instala XoniTube
  installxoni xonigraf      : Instala XoniGraf
  installxoni xonichat      : Instala XoniChat

CONFIGURACION DE RED:
  nmtui                     : Configurar red
  wifi-menu                 : Conectar a WiFi

INFORMACION DEL SISTEMA:
  neofetch                  : Info del sistema
  htop                      : Monitor de procesos
  sensors                   : Temperaturas
  lsblk                     : Discos disponibles

ENTORNO GRAFICO:
  La terminal principal NO se puede cerrar
  Windows + x               : Menu
  Windows + t               : Nueva terminal
  Windows + h               : Ayuda
  Windows + i               : Instalar herramienta

REPOSITORIO:
  https://github.com/xonidu/xoniarch32
EOT
EOF
chmod +x /usr/local/bin/xoniarch-help

# xoniarch-menu
cat > /usr/local/bin/xoniarch-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "========================================"
    echo "      XONIARCH32 - MENU"
    echo "========================================"
    echo "1) Nueva terminal"
    echo "2) Instalar herramienta XONI"
    echo "3) Ver herramientas instaladas"
    echo "4) Configurar red (nmtui)"
    echo "5) Monitor del sistema (htop)"
    echo "6) Gestor de archivos"
    echo "7) Ayuda"
    echo "8) Cerrar sesion"
    echo ""
    read -p "Opcion [1-8]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e installxoni ; read -p "Presiona Enter..." ;;
        3) urxvt -e ls -la /opt/xoniarch ; read -p "Presiona Enter..." ;;
        4) urxvt -e nmtui ;;
        5) urxvt -e htop ;;
        6) pcmanfm ;;
        7) xoniarch-help ; read -p "Presiona Enter..." ;;
        8) openbox --exit ;;
        *) echo "Opcion invalida"; sleep 2 ;;
    esac
done
EOF
chmod +x /usr/local/bin/xoniarch-menu

# ============================================
# PASO 11: CONFIGURACION DEL SISTEMA
# ============================================
echo -e "${YELLOW}[11/12] Configurando servicios del sistema...${NC}"

# Habilitar servicios
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sshd
systemctl enable tlp
systemctl enable acpid

# Configurar sensors
sensors-detect --auto 2>/dev/null || true

# Crear directorio para fondos de pantalla
mkdir -p /usr/share/backgrounds

# ============================================
# PASO 12: PERMISOS Y MENSAJE FINAL
# ============================================
echo -e "${YELLOW}[12/12] Ajustando permisos...${NC}"

# Cambiar propietario de archivos de usuario
chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.xinitrc"
chown -R "$REAL_USER:$REAL_USER" /opt/xoniarch 2>/dev/null || true

# Anadir usuario a grupos necesarios
usermod -aG wheel,audio,video,storage,power,docker "$REAL_USER"

# Mensaje de bienvenida
cat > /etc/motd << 'EOF'
========================================
   XONIARCH32 - INSTALADO
========================================

✅ INSTALACION COMPLETADA

🔐 ACCESO:
   El sistema iniciara directamente en modo grafico
   Usuario: xoniarch / Contraseña: la que pusiste

🖥️ TERMINAL FIJA:
   La terminal principal NO se puede cerrar
   Usa Windows + t para abrir nuevas terminales

📦 INSTALAR HERRAMIENTAS:
   installxoni <nombre>    : Instalar herramienta
   Ejemplo: installxoni xonitube

📋 COMANDOS RAPIDOS:
   xoniarch-menu          : Menu interactivo
   xoniarch-help          : Ayuda completa
   Windows + x            : Menu
   Windows + i            : Instalar herramienta

🌐 REPOSITORIO:
   https://github.com/xonidu/xoniarch32
========================================
EOF

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALACION COMPLETADA              ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}COMANDOS DISPONIBLES:${NC}"
echo "  installxoni <herramienta> : Instalar herramienta XONI"
echo "  xoniarch-help             : Ayuda completa"
echo "  xoniarch-menu             : Menu interactivo"
echo ""
echo -e "${YELLOW}EJEMPLOS:${NC}"
echo "  installxoni xonitube      : Instalar XoniTube"
echo "  installxoni xonigraf      : Instalar XoniGraf"
echo "  installxoni xonichat      : Instalar XoniChat"
echo ""
echo -e "${YELLOW}REINICIO:${NC}"
echo "  sudo reboot"
echo ""
echo -e "${GREEN}¡Xoniarch32 esta listo!${NC}"
echo -e "${YELLOW}Al reiniciar, entrara DIRECTAMENTE al modo grafico${NC}"
echo -e "${YELLOW}con la terminal principal fija (no se puede cerrar)${NC}"
