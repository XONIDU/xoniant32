#!/bin/bash
# XONIARCH32 v5.0 – Instalador universal para sistemas de 32 bits
# Autor: Darian Alberto Camacho Salas
# Repositorio: https://github.com/XONIDU/xoniarch32
#
# Este script instala un sistema completo listo para usar:
#   - Kernel Linux estándar
#   - Xorg + Openbox con terminal fija
#   - Gestor de inicio lightdm (si disponible) o inicio manual con startx
#   - Controladores de video genéricos (vesa)
#   - Herramientas XONI para instalar desde GitHub
#   - Pregunta nombre de usuario, contraseña y nombre del equipo

set -euo pipefail
trap 'echo -e "\033[0;31m[ERROR] Falló en la línea $LINENO\033[0m" >&2' ERR

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

error_exit() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info()  { echo -e "${GREEN}[INFO] $1${NC}"; }
warn()  { echo -e "${YELLOW}[AVISO] $1${NC}"; }

# ============================================
# 1. Verificar entorno live
# ============================================
if [ ! -d /run/archiso ]; then
    error_exit "Este script debe ejecutarse desde el live USB de Arch Linux 32 bits."
fi

# ============================================
# 2. Seleccionar disco de instalación
# ============================================
clear
echo "========================================"
echo "   XONIARCH32 v5.0 - INSTALADOR        "
echo "========================================"
echo ""
echo "Discos disponibles:"
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E "disk|NAME"
echo ""
read -p "¿En qué disco quieres instalar Xoniarch32? (ej: sda): " DISK
[ -z "$DISK" ] && error_exit "No se seleccionó ningún disco."
[ ! -b "/dev/$DISK" ] && error_exit "El disco /dev/$DISK no existe."

echo ""
echo "¡ATENCION! Se borrarán TODOS los datos en /dev/$DISK"
lsblk "/dev/$DISK"
read -p "¿Estás seguro? (escribe YES): " CONFIRM
[ "$CONFIRM" != "YES" ] && error_exit "Instalación cancelada."

# ============================================
# 3. Opciones de particionado
# ============================================
echo ""
echo "Elige el tipo de particionado:"
echo "1) Automático (swap opcional)"
echo "2) Manual (usar fdisk tú mismo)"
read -p "Opcion [1/2]: " PART_OPT

if [ "$PART_OPT" = "1" ]; then
    read -p "¿Crear partición swap? (s/n): " SWAP_OPT
    if [[ "$SWAP_OPT" =~ ^[Ss]$ ]]; then
        read -p "Tamaño de swap en GB (ej: 1): " SWAP_SIZE
        SWAP_SIZE=${SWAP_SIZE:-1}
        info "Particionando /dev/$DISK con swap de ${SWAP_SIZE}G..."
        parted "/dev/$DISK" mklabel msdos
        parted "/dev/$DISK" mkpart primary linux-swap 1MiB "${SWAP_SIZE}GiB"
        parted "/dev/$DISK" mkpart primary ext4 "${SWAP_SIZE}GiB" 100%
        parted "/dev/$DISK" set 2 boot on
        ROOT_PART="${DISK}2"
        SWAP_PART="${DISK}1"
    else
        info "Particionando /dev/$DISK sin swap..."
        parted "/dev/$DISK" mklabel msdos
        parted "/dev/$DISK" mkpart primary ext4 1MiB 100%
        parted "/dev/$DISK" set 1 boot on
        ROOT_PART="${DISK}1"
        SWAP_PART=""
    fi

    info "Formateando particiones..."
    mkfs.ext4 -F "/dev/$ROOT_PART"
    [ -n "$SWAP_PART" ] && mkswap "/dev/$SWAP_PART"
else
    info "Abriendo fdisk para particionado manual. Cuando termines, escribe 'exit' para continuar."
    fdisk "/dev/$DISK"
    echo ""
    lsblk "/dev/$DISK"
    read -p "Indica la partición raíz (ej: ${DISK}2): " ROOT_PART
    [ -z "$ROOT_PART" ] && error_exit "No se indicó partición raíz."
    read -p "Indica la partición swap (dejar vacío si no hay): " SWAP_PART
fi

# Montar sistema
info "Montando sistema en /mnt..."
mount "/dev/$ROOT_PART" /mnt
[ -n "$SWAP_PART" ] && swapon "/dev/$SWAP_PART" 2>/dev/null || true

# ============================================
# 4. Configurar pacman con mirrors
# ============================================
info "Configurando mirrors de archlinux32..."

MIRRORS=(
    "https://mirror.archlinux32.org"
    "https://ftp.halifax.rwth-aachen.de/archlinux32"
    "https://mirror.cyberbits.eu/archlinux32"
    "https://mirror.ubnt.net/archlinux32"
)

best_mirror=""
for mirror in "${MIRRORS[@]}"; do
    echo -n "Probando $mirror ... "
    if curl -s --head --max-time 5 "${mirror}/core/os/i686/core.db" >/dev/null 2>&1; then
        echo "OK"
        best_mirror="$mirror"
        break
    else
        echo "FALLÓ"
    fi
done

if [ -z "$best_mirror" ]; then
    warn "No se encontró mirror funcional. Usando el primero."
    best_mirror="https://mirror.archlinux32.org"
fi

cat > /etc/pacman.conf << EOF
[options]
HoldPkg         = pacman glibc
Architecture    = i686
SigLevel        = Never
LocalFileSigLevel = Never
RemoteFileSigLevel = Never
ParallelDownloads = 5
Color
CheckSpace
DisableDownloadTimeout
Timeout = 30

[core]
Server = $best_mirror/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo

[extra]
Server = $best_mirror/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo

[community]
Server = $best_mirror/\$arch/\$repo
Server = https://mirror.archlinux32.org/\$arch/\$repo
EOF

# ============================================
# 5. Inicializar claves PGP
# ============================================
info "Inicializando claves PGP..."
pacman-key --init 2>/dev/null || true
pacman-key --populate archlinux32 2>/dev/null || true
pacman -Sy --noconfirm archlinux32-keyring 2>/dev/null || true

# ============================================
# 6. Instalar sistema base (con reintentos)
# ============================================
info "Instalando sistema base (puede tardar 10-20 minutos)..."
max_retries=5
retry=0
while [ $retry -lt $max_retries ]; do
    if pacstrap /mnt base base-devel linux linux-firmware grub networkmanager sudo git nano; then
        break
    else
        retry=$((retry+1))
        warn "Falló la instalación base. Reintento $retry de $max_retries en 10 segundos..."
        sleep 10
    fi
done
if [ $retry -eq $max_retries ]; then
    error_exit "Falló la instalación base después de varios intentos."
fi

# ============================================
# 7. Generar fstab
# ============================================
info "Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ============================================
# 8. Preguntar datos del usuario
# ============================================
clear
echo "========================================"
echo "   CONFIGURACIÓN DEL SISTEMA           "
echo "========================================"
echo ""
read -p "Nombre del equipo (hostname) [xoniarch]: " HOSTNAME
HOSTNAME=${HOSTNAME:-xoniarch}
read -p "Nombre de usuario [xoniarch]: " USERNAME
USERNAME=${USERNAME:-xoniarch}
while true; do
    read -s -p "Contraseña para $USERNAME: " PASSWORD1
    echo
    read -s -p "Repite la contraseña: " PASSWORD2
    echo
    if [ "$PASSWORD1" = "$PASSWORD2" ] && [ -n "$PASSWORD1" ]; then
        PASSWORD="$PASSWORD1"
        break
    else
        echo "Las contraseñas no coinciden o están vacías. Intenta de nuevo."
    fi
done

# ============================================
# 9. Configuración básica dentro del chroot
# ============================================
info "Configurando sistema base..."

cat > /mnt/root/chroot-config.sh << CONFIG
#!/bin/bash
# Zona horaria
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

# Localización
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Usuario y sudo
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Habilitar servicios
systemctl enable NetworkManager
CONFIG

chmod +x /mnt/root/chroot-config.sh
arch-chroot /mnt /root/chroot-config.sh

# ============================================
# 10. Instalar GRUB (usando UUID para mayor compatibilidad)
# ============================================
info "Instalando GRUB..."
arch-chroot /mnt grub-install --target=i386-pc "/dev/$DISK"
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Verificar que el kernel esté presente
if [ ! -f /mnt/boot/vmlinuz-linux ]; then
    warn "Kernel no encontrado. Intentando reinstalar linux..."
    arch-chroot /mnt pacman -S --noconfirm linux
fi

# ============================================
# 11. Instalar paquetes esenciales para Xorg (con verificación)
# ============================================
info "Instalando paquetes esenciales (Xorg, Openbox, etc.)..."

# Lista de paquetes base
PACKAGES=(
    xorg-server
    xorg-xinit
    xorg-xrandr
    xterm
    openbox
    tint2
    feh
    picom
    rxvt-unicode
    alsa-utils
    pulseaudio
    xf86-video-vesa
    mesa
    lightdm
    lightdm-gtk-greeter
)

# Instalar paquete si está disponible
for pkg in "${PACKAGES[@]}"; do
    echo "Verificando $pkg..."
    if pacman -Sp "$pkg" &>/dev/null; then
        arch-chroot /mnt pacman -S --noconfirm "$pkg" && echo "[OK] $pkg instalado" || warn "Falló instalación de $pkg"
    else
        warn "$pkg no está disponible para i686. Omitiendo."
    fi
done

# Habilitar lightdm si se instaló
if [ -f /mnt/usr/lib/systemd/system/lightdm.service ]; then
    arch-chroot /mnt systemctl enable lightdm
    DM_INSTALLED=1
else
    warn "LightDM no instalado. El sistema arrancará en consola. Usa 'startx' para iniciar gráficos."
    DM_INSTALLED=0
fi

# ============================================
# 12. Configuración de Openbox (terminal fija)
# ============================================
info "Configurando Openbox con terminal fija..."
mkdir -p /mnt/etc/skel/.config/openbox

cat > /mnt/etc/skel/.config/openbox/rc.xml << 'EOF'
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

cat > /mnt/etc/skel/.config/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu>
  <menu id="root-menu" label="Xoniarch32">
    <item label="Nueva terminal"><action name="Execute"><command>urxvt</command></action></item>
    <item label="Instalar herramienta XONI"><action name="Execute"><command>urxvt -e installxoni</command></action></item>
    <item label="Configurar red"><action name="Execute"><command>urxvt -e nmtui</command></action></item>
    <item label="Monitor sistema"><action name="Execute"><command>urxvt -e htop</command></action></item>
    <item label="Ayuda"><action name="Execute"><command>urxvt -e xoniarch-help</command></action></item>
    <item label="Cerrar sesión"><action name="Exit"/></item>
  </menu>
</openbox_menu>
EOF

cat > /mnt/etc/skel/.config/openbox/autostart << 'EOF'
feh --bg-scale /usr/share/backgrounds/default.jpg &
picom -b &
tint2 &
urxvt -title "principal" &
EOF

cat > /mnt/etc/skel/.xinitrc << 'EOF'
#!/bin/sh
exec openbox-session
EOF

# ============================================
# 13. Scripts personalizados de Xoniarch
# ============================================
info "Creando scripts de Xoniarch..."
mkdir -p /mnt/usr/local/bin

cat > /mnt/usr/local/bin/installxoni << 'EOF'
#!/bin/bash
REPO_BASE="https://github.com/XONIDU"
DIR="/opt/xoniarch"
[ ! -d "$DIR" ] && mkdir -p "$DIR"
cd "$DIR"
if [ -z "$1" ]; then
    read -p "Herramienta a instalar (ej: xonitube): " TOOL
else
    TOOL="$1"
fi
if [ -d "$TOOL" ]; then
    cd "$TOOL" && git pull && cd ..
else
    git clone "$REPO_BASE/$TOOL.git"
fi
find "$TOOL" -name "*.py" -o -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
for f in $(find "$TOOL" -maxdepth 2 -name "*.py" -o -name "*.sh" 2>/dev/null | grep -v "__"); do
    ln -sf "$(pwd)/$f" "/usr/local/bin/$(basename $f .py)" 2>/dev/null || true
    ln -sf "$(pwd)/$f" "/usr/local/bin/$(basename $f .sh)" 2>/dev/null || true
done
echo "[OK] $TOOL instalado"
EOF

cat > /mnt/usr/local/bin/xoniarch-update << 'EOF'
#!/bin/bash
cd /opt/xoniarch
for tool in */; do
    [ -d "$tool" ] && (cd "$tool" && git pull)
done
echo "[OK] Actualización completada"
EOF

cat > /mnt/usr/local/bin/xoniarch-help << 'EOF'
#!/bin/bash
cat << 'HELP'
========================================
   XONIARCH32 v5.0 - AYUDA
========================================
COMANDOS:
  installxoni <herramienta>  : Instalar herramienta XONI desde GitHub
  xoniarch-update            : Actualizar todas las herramientas instaladas
  xoniarch-menu               : Abrir menú interactivo
  nmtui                       : Configurar red WiFi/Ethernet
  htop                        : Monitor del sistema
  pcmanfm                     : Gestor de archivos
  alsamixer                   : Ajustar volumen

ATAJOS DE TECLADO:
  Win + x   : Menú principal
  Win + t   : Nueva terminal
  Win + h   : Ayuda
  Win + i   : Instalar herramienta
  Win + q   : Cerrar sesión

USUARIO: $USERNAME (el que elegiste)
REPOSITORIO: https://github.com/XONIDU/xoniarch32
HELP
EOF

cat > /mnt/usr/local/bin/xoniarch-menu << 'EOF'
#!/bin/bash
while true; do
    clear
    echo "========================================"
    echo "      XONIARCH32 - MENU PRINCIPAL"
    echo "========================================"
    echo "1) Nueva terminal"
    echo "2) Instalar herramienta XONI"
    echo "3) Configurar red (nmtui)"
    echo "4) Monitor del sistema (htop)"
    echo "5) Gestor de archivos (pcmanfm)"
    echo "6) Ayuda"
    echo "7) Cerrar sesión"
    echo ""
    read -p "Opción [1-7]: " opt
    case $opt in
        1) urxvt ;;
        2) urxvt -e installxoni ; read -p "Presiona Enter..." ;;
        3) urxvt -e nmtui ;;
        4) urxvt -e htop ;;
        5) pcmanfm ;;
        6) xoniarch-help ; read -p "Presiona Enter..." ;;
        7) openbox --exit ;;
        *) echo "Opción inválida"; sleep 2 ;;
    esac
done
EOF

chmod +x /mnt/usr/local/bin/*

# ============================================
# 14. .bashrc personalizado
# ============================================
cat > /mnt/etc/skel/.bashrc << 'EOF'
alias ll='ls -la'
alias la='ls -A'
alias update='xoniarch-update'
alias menu='xoniarch-menu'
alias help='xoniarch-help'
PS1='\[\e[1;32m\][\u@\h \W]\$ \[\e[0m\]'
EOF
cp /mnt/etc/skel/.bashrc "/mnt/home/$USERNAME/" 2>/dev/null || true

# ============================================
# 15. Fondo de pantalla por defecto
# ============================================
mkdir -p /mnt/usr/share/backgrounds
touch /mnt/usr/share/backgrounds/default.jpg

# ============================================
# 16. Mensaje de bienvenida (MOTD)
# ============================================
cat > /mnt/etc/motd << 'EOF'
========================================
   XONIARCH32 v5.0 - LISTO
   by Darian Alberto Camacho Salas
========================================

Instalación completada con éxito.
Usuario: (el que elegiste)
Contraseña: la que configuraste

El sistema arrancará en modo gráfico (si LightDM está instalado).
La terminal principal es fija (no se puede cerrar).

Comandos útiles:
  xoniarch-help     : Ayuda completa
  xoniarch-menu     : Menú interactivo
  installxoni       : Instalar herramientas XONI desde GitHub
  xoniarch-update   : Actualizar herramientas
  nmtui             : Configurar red

Repositorio: https://github.com/XONIDU/xoniarch32
EOF

# ============================================
# 17. Verificar GRUB y kernel
# ============================================
if [ ! -f /mnt/boot/grub/grub.cfg ]; then
    warn "grub.cfg no generado. Creando uno manual..."
    root_uuid=$(blkid -s UUID -o value "/dev/$ROOT_PART")
    cat > /mnt/boot/grub/grub.cfg << GRUB
set timeout=5
set default=0

menuentry "Xoniarch32" {
    linux /boot/vmlinuz-linux root=UUID=$root_uuid rw quiet
    initrd /boot/initramfs-linux.img
}
GRUB
fi

# ============================================
# 18. Limpieza y finalización
# ============================================
rm -f /mnt/root/chroot-config.sh
umount -R /mnt 2>/dev/null || true
[ -n "$SWAP_PART" ] && swapoff "/dev/$SWAP_PART" 2>/dev/null || true

echo "========================================"
echo "   INSTALACIÓN COMPLETADA              "
echo "========================================"
echo ""
echo "Reinicia el sistema con: sudo reboot"
echo ""
echo "Usuario: $USERNAME | Contraseña: la que elegiste"
echo "Root:    root     | Contraseña: la misma"
echo ""
echo "Después del reinicio, ejecuta 'xoniarch-help' para más información."
