#!/usr/bin/env bash
#========================================================
#  BootRepair v0.1.1
#  License: MIT
#  Description: Swiss-army live rescue tool: GRUB repair, display reset,
#               initramfs, kernel, system update, boot freedom, diagnostics.
#  Supports: Arch/EndeavourOS/CachyOS, Debian/Ubuntu/Mint/Pop, Fedora,
#            openSUSE, NixOS (best-effort)
#========================================================

set -euo pipefail

START_TIME=$(date +%s)

# Colors
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; CYAN="\e[36m"; RESET="\e[0m"

#-----------------------
# Language (EN/ES/DE/PT)
#-----------------------
LANG_CODE="en"
case "${LANG:-es}" in
  en_*|en) LANG_CODE="en" ;;
  *) LANG_CODE="en" ;;
esac

declare -A T
if [[ "$LANG_CODE" == "en" ]]; then
  T[title]="BootRepair"
  T[gather]="Gathering system information..."
  T[detected_distro]="Detected distribution"
  T[detected_arch]="Detected architecture"
  T[detected_mode]="Detected boot mode"
  T[secureboot]="Secure Boot status"
  T[secure_on]="ENABLED"
  T[secure_off]="DISABLED"
  T[secure_unknown]="Unknown"
  T[menu_title]="Main menu"
  T[m1]="1) Repair GRUB"
  T[m2]="2) Reset monitor configs (Wayland/Hyprland/Xorg)"
  T[m3]="3) Regenerate initramfs"
  T[m4]="4) Reinstall kernel"
  T[m5]="5) Update operating system"
  T[m6]="6) Boot freedom (timeout, default, EFI, os-prober)"
  T[m7]="7) Quick diagnostics"
  T[m8]="8) Settings (language, expert mode, install alias)"
  T[m9]="10) Exit"
  T[enter_choice]="Choose an option"
  T[press_enter]="Press Enter to continue..."
  T[need_root]="This script requires administrator privileges (sudo)."
  T[warn_boot]="WARNING: This will modify your bootloader."
  T[proceed]="Do you want to proceed? [y/N]: "
  T[cancelled]="Operation cancelled."
  T[auto_mode]="Automatic mode? (detect root/EFI) [y/N]: "
  T[select_root]="Select your root partition"
  T[select_efi]="Select your EFI partition (vfat, ~100–500 MB)"
  T[efi_hint]="Hint: pick vfat/FAT32 partition labeled EFI/ESP."
  T[no_parts]="No suitable partitions detected."
  T[invalid_sel]="Invalid selection."
  T[mounting]="Mounting and preparing chroot..."
  T[binds]="Performing bind mounts..."
  T[repairing_for]="Running GRUB repair for"
  T[done]="Done."
  T[total_time]="Total time"
  T[reboot_now]="Reboot now? [y/N]: "
  T[rebooting]="Rebooting..."
  T[reboot_later]="You can reboot later manually."
  T[bios_disk]="Select disk to install GRUB (BIOS/Legacy)"
  T[disk_from_root]="Determining disk from selected root..."
  T[uefi_skip_disk]="In UEFI you don't need to select a disk."
  T[pkg_hint]="Make sure grub is installed in the target system."
  T[nixos_hint]="In NixOS, changes are applied via nixos-rebuild."
  T[auto_detecting]="Auto-detecting partitions..."
  T[auto_fail]="Auto-detection failed. Switching to manual selection."
  T[selected]="Selected"
  T[boot_name]="Name for UEFI menu? (default: Linux) >> "
  T[gpu_note]="Resetting monitor configs for Wayland/Hyprland and Xorg."
  T[initramfs_done]="initramfs regenerated (when applicable)."
  T[kernel_note]="Will try to reinstall kernel via package manager."
  T[diag_title]="System diagnostics"
  T[settings_title]="Settings"
  T[set_lang]="1) Change language (EN)"
  T[set_expert]="2) Toggle expert mode"
  T[set_install]="3) Install 'bootrepair' to /usr/local/bin (Only for GIT version)"
  T[back]="7) Back"
  T[expert_on]="Expert mode ENABLED"
  T[expert_off]="Expert mode DISABLED"
  T[installed_alias]="'bootrepair' installed"
  T[already_alias]="/usr/local/bin/bootrepair already exists"
  T[bootcfg_title]="Boot freedom"
  T[bc1]="1) Change GRUB timeout"
  T[bc2]="2) Change GRUB default entry"
  T[bc3]="3) Enable os-prober and regenerate"
  T[bc4]="4) Manage EFI entries (list/order/bootnext)"
  T[bc5]="5) Back"
  T[enter_timeout]="New timeout (seconds) >> "
  T[enter_default]="New default entry (e.g., 0 or 'Advanced options>...') >> "
  T[updated]="Updated."
  T[efimenu]="EFI: 1) List  2) Set order  3) Set BootNext  4) Back"
  T[enter_order]="Enter order (e.g., 0003,0001,0000) >> "
  T[enter_bootnext]="Enter BootNext (e.g., 0003) >> "
  T[update_title]="Update operating system"
  T[update_warn]="This will update packages on the target system."
  T[updating]="Updating..."
  T[set_uninstall]="4) Uninstall 'bootrepair' from /usr/local/bin"
  T[uninstalled_alias]="'boot repair' removed from /usr/local/bin"
  T[no_alias]="'bootrepair' is not installed in /usr/local/bin"

fi

EXPERT=false

#-----------------------
# Banner
#-----------------------
ascii_banner() {
  echo -e "${CYAN}"
  cat << "EOF"
,--.                   ,--.                                      ,--.       
|  |-.  ,---.  ,---. ,-'  '-.,-----.,--.--. ,---.  ,---.  ,--,--.`--',--.--.
| .-. '| .-. || .-. |'-.  .-''-----'|  .--'| .-. :| .-. |' ,-.  |,--.|  .--'
| `-' |' '-' '' '-' '  |  |         |  |   \   --.| '-' '\ '-'  ||  ||  |   
 `---'  `---'  `---'   `--'         `--'    `----'|  |-'  `--`--'`--'`--'   
EOF
  echo -e "${RESET}"
  echo -e "${YELLOW}=== ${T[title]} v0.1.1 Beta ===${RESET}"
}

pause() { read -r -p "${T[press_enter]}" _ </dev/tty; }
need_root() { [[ $EUID -eq 0 ]] || { echo -e "${RED}${T[need_root]}${RESET}"; exit 1; }; }
read_tty() { local prompt="$1"; local __var="$2"; read -r -p "$prompt" "$__var" </dev/tty; }

#-----------------------
# Info header
#-----------------------
secure_boot_status() {
  if [[ ! -d /sys/firmware/efi ]]; then echo "BIOS/Legacy"; return; fi
  if command -v mokutil &>/dev/null; then
    if mokutil --sb-state 2>/dev/null | grep -qi enabled; then echo "${T[secure_on]}"; return; fi
    if mokutil --sb-state 2>/dev/null | grep -qi disabled; then echo "${T[secure_off]}"; return; fi
    echo "${T[secure_unknown]}"; return
  fi
  local var; var=$(ls /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | head -n1 || true)
  if [[ -n "$var" ]]; then
    local state; state=$(hexdump -v -e '/1 "%u "' "$var" 2>/dev/null | awk '{print $5}')
    case "$state" in 1) echo "${T[secure_on]}";; 0) echo "${T[secure_off]}";; *) echo "${T[secure_unknown]}";; esac
  else
    echo "${T[secure_unknown]}"
  fi
}

info_header() {
  echo -e "${CYAN}${T[gather]}${RESET}"
  echo "Hostname: $(hostname)"
  echo "Kernel: $(uname -r)"
  ARCH=$(uname -m)
  echo "${T[detected_arch]}: $ARCH"

  # Motherboard
  if command -v dmidecode &>/dev/null; then
    echo "Motherboard: $(dmidecode -s baseboard-manufacturer 2>/dev/null) $(dmidecode -s baseboard-product-name 2>/dev/null)"
  fi

  # Distro
  DISTRO="unknown"
  if [[ -f /etc/os-release ]]; then . /etc/os-release; DISTRO="$PRETTY_NAME"; fi
  echo -e "${GREEN}${T[detected_distro]}:${RESET} $DISTRO"

  # Boot mode
  if [[ -d /sys/firmware/efi/efivars ]]; then BOOT_MODE="UEFI"; else BOOT_MODE="BIOS"; fi
  echo -e "${GREEN}${T[detected_mode]}:${RESET} $BOOT_MODE"
  echo -e "${GREEN}${T[secureboot]}:${RESET} $(secure_boot_status)"

  echo "-----------------------------------"

  # CPU
  CPU=$(lscpu | grep "Model name" | sed 's/Model name:\s*//')
  echo "CPU: $CPU"

  # GPU (si hay)
  if command -v lspci &>/dev/null; then
    GPU=$(lspci | grep -i 'vga' | sed 's/.*: //')
    echo "GPU: $GPU"
  fi

  # RAM
  MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
  MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
  echo "RAM: $MEM_USED / $MEM_TOTAL"

  # Disco raíz
  DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
  DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
  echo "Disk (/): $DISK_USED / $DISK_TOTAL"

  # Uptime
  echo "Uptime: $(uptime -p)"

  # Shell
  echo "Shell: $SHELL"

  # Terminal
  echo "Terminal: $TERM"

  # Usuarios conectados
  echo "Logged users: $(who | wc -l)"

  echo "-----------------------------------"
}


#-----------------------
# Helpers
#-----------------------
list_parts() { lsblk -rpno NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,PARTLABEL,PARTTYPE; }
list_disks() { lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}'; }
select_from() {
  local prompt="$1"; shift
  local -a items=("$@")
  [[ ${#items[@]} -gt 0 ]] || { echo -e "${RED}${T[no_parts]}${RESET}"; return 1; }
  echo -e "${CYAN}$prompt:${RESET}"
  local i=1; for it in "${items[@]}"; do echo "  $i) $it"; ((i++)); done
  local idx; read -r -p ">> " idx </dev/tty
  [[ "$idx" =~ ^[0-9]+$ ]] && (( idx>=1 && idx<=${#items[@]} )) || { echo -e "${RED}${T[invalid_sel]}${RESET}"; return 2; }
  echo "${items[$((idx-1))]}"
}
detect_targets() {
  case "$(uname -m)" in
    x86_64) echo "x86_64-efi|i386-pc" ;;
    i686|i386) echo "i386-efi|i386-pc" ;;
    aarch64|arm64) echo "aarch64-efi|" ;;
    armv7l|armv8l) echo "arm-efi|" ;;
    *) echo "x86_64-efi|i386-pc" ;;
  esac
}
auto_detect_parts() {
  echo -e "${CYAN}${T[auto_detecting]}${RESET}"
  local root=""; local efi=""
  root=$(list_parts | awk '$3=="part" && ($4=="ext4"||$4=="btrfs"||$4=="xfs"||$4=="f2fs"){print $1" "$2}' | sort -k2 -h | tail -n1 | awk '{print $1}')
  efi=$(list_parts | awk '$3=="part" && ($4=="vfat"||$4=="fat32"){print $1" "$6" "$7" "$8}' | awk 'tolower($2) ~ /efi|esp/ || tolower($3) ~ /efi|esp/ {print $1; found=1} END {if(!found) exit 1}' 2>/dev/null || true)
  [[ -z "$efi" ]] && efi=$(list_parts | awk '$3=="part" && ($4=="vfat"||$4=="fat32"){print $1}' | head -n1)
  [[ -n "$root" ]] && echo "ROOT=$root"
  [[ -n "$efi" ]] && echo "EFI=$efi"
}
prepare_chroot() {
  local root_part="$1"; local efi_part="${2:-}"
  echo -e "${CYAN}${T[mounting]}${RESET}"
  mkdir -p /mnt
  mountpoint -q /mnt || mount "$root_part" /mnt
  mkdir -p /mnt/boot
  if [[ -n "$efi_part" ]]; then
    mkdir -p /mnt/boot/efi
    mountpoint -q /mnt/boot/efi || mount "$efi_part" /mnt/boot/efi
  fi
  echo -e "${CYAN}${T[binds]}${RESET}"
  for d in dev proc sys run; do mountpoint -q /mnt/$d || mount --bind /$d /mnt/$d; done
}
distro_in_chroot() { local id="unknown"; [[ -f /mnt/etc/os-release ]] && . /mnt/etc/os-release && id="$ID"; echo "$id"; }

#-----------------------
# Modules
#-----------------------
grub_repair() {
    # Colors
    RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"

    # Detect distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "${RED}Cannot detect your distribution.${RESET}"
        return 1
    fi
    echo -e "${GREEN}Detected distribution:${RESET} $DISTRO"

    # Select boot mode
    echo -e "${CYAN}Select boot mode:${RESET}"
    echo "1) UEFI (recommended)"
    echo "2) BIOS (Legacy)"
    read -rp "Choice [1/2]: " BOOT_MODE
    if [ "$BOOT_MODE" != "1" ] && [ "$BOOT_MODE" != "2" ]; then
        echo -e "${RED}Invalid choice. Defaulting to UEFI.${RESET}"
        BOOT_MODE=1
    fi

    # Confirm repair
    echo -e "${YELLOW}WARNING:${RESET} This will modify your bootloader."
    read -rp "Do you want to proceed? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operation cancelled.${RESET}"
        return 0
    fi

    # Mount partitions
    read -rp "Enter your root partition (e.g., /dev/sda2): " ROOT_PART
    if [ "$BOOT_MODE" = "1" ]; then
        read -rp "Enter your EFI partition (e.g., /dev/sda1): " EFI_PART
    fi
    echo -e "${CYAN}Mounting partitions...${RESET}"
    sudo mount "$ROOT_PART" /mnt
    if [ "$BOOT_MODE" = "1" ]; then
        sudo mount "$EFI_PART" /mnt/boot/efi
    fi

    # Helper: run commands in chroot (prefers arch-chroot if available)
    run_in_chroot() {
        if command -v arch-chroot >/dev/null; then
            sudo arch-chroot /mnt /bin/bash -c "$1"
        else
            sudo mount --bind /dev /mnt/dev
            sudo mount --bind /proc /mnt/proc
            sudo mount --bind /sys /mnt/sys
            sudo chroot /mnt /bin/bash -c "$1"
        fi
    }

    # Repair GRUB based on distro
    case "$DISTRO" in
        arch|endeavouros|cachyos)
            echo -e "${YELLOW}Running Arch-based GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                run_in_chroot "
                    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    grub-mkconfig -o /boot/grub/grub.cfg
                "
            else
                run_in_chroot "
                    grub-install --target=i386-pc /dev/sda &&
                    grub-mkconfig -o /boot/grub/grub.cfg
                "
            fi
            ;;
        debian|ubuntu)
            echo -e "${YELLOW}Running Debian/Ubuntu GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                run_in_chroot "
                    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    update-grub
                "
            else
                run_in_chroot "
                    grub-install --target=i386-pc /dev/sda &&
                    update-grub
                "
            fi
            ;;
        fedora)
            echo -e "${YELLOW}Running Fedora GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                run_in_chroot "
                    grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            else
                run_in_chroot "
                    grub2-install --target=i386-pc /dev/sda &&
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            fi
            ;;
        opensuse*|suse)
            echo -e "${YELLOW}Running openSUSE GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                run_in_chroot "
                    grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            else
                run_in_chroot "
                    grub2-install --target=i386-pc /dev/sda &&
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            fi
            ;;
        nixos)
            echo -e "${YELLOW}Running NixOS GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo nixos-enter /mnt --command "
                    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    nixos-rebuild boot
                "
            else
                sudo nixos-enter /mnt --command "
                    grub-install --target=i386-pc /dev/sda &&
                    nixos-rebuild boot
                "
            fi
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${RESET}"
            return 1
            ;;
    esac

    echo -e "${GREEN}GRUB repair completed successfully.${RESET}"
}

grub_repair_experimental() {
    RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"
    TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
    LOGFILE="/var/log/grub_repair_${TIMESTAMP}.log"

    echo -e "${CYAN}=== GRUB Repair Experimental ===${RESET}"
    [[ $EUID -ne 0 ]] && { echo -e "${RED}Debes ser root.${RESET}"; return 1; }

    # Detect distro
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "${RED}No se pudo detectar la distribución.${RESET}"
        return 1
    fi
    echo -e "${GREEN}Distro detectada:${RESET} $DISTRO"

    # Detect boot mode
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="UEFI"
    else
        BOOT_MODE="BIOS"
    fi
    echo -e "${GREEN}Modo detectado:${RESET} $BOOT_MODE"

    # Ask partitions
    read -rp "Partición raíz (ej: /dev/sda2): " ROOT_PART
    if [ "$BOOT_MODE" = "UEFI" ]; then
        read -rp "Partición EFI (ej: /dev/sda1): " EFI_PART
    fi

    # Mount
    mount "$ROOT_PART" /mnt || return 1
    if [ "$BOOT_MODE" = "UEFI" ]; then
        mkdir -p /mnt/boot/efi
        mount "$EFI_PART" /mnt/boot/efi || return 1
    fi

    # Backup automático
    if [ "$BOOT_MODE" = "UEFI" ]; then
        BACKUP_DIR="/mnt/boot/efi/EFI/Backup_${TIMESTAMP}"
        mkdir -p "$BACKUP_DIR"
        cp -a /mnt/boot/efi/EFI/* "$BACKUP_DIR"/ 2>/dev/null || true
        efibootmgr -v > "$LOGFILE.nvram" 2>/dev/null || true
        echo -e "${YELLOW}Backup del ESP en:${RESET} $BACKUP_DIR"
        echo -e "${YELLOW}Entradas NVRAM guardadas en:${RESET} $LOGFILE.nvram"
    fi

    # Helper chroot
    run_in_chroot() {
        if command -v arch-chroot >/dev/null; then
            arch-chroot /mnt /bin/bash -c "$1"
        else
            mount --bind /dev /mnt/dev
            mount --bind /proc /mnt/proc
            mount --bind /sys /mnt/sys
            chroot /mnt /bin/bash -c "$1"
        fi
    }

    # Install GRUB
    case "$DISTRO" in
        arch|endeavouros|cachyos)
            if [ "$BOOT_MODE" = "UEFI" ]; then
                run_in_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux --no-nvram --recheck"
                run_in_chroot "cp -f /boot/efi/EFI/Linux/grubx64.efi /boot/efi/EFI/Boot/bootx64.efi || true"
                run_in_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
            else
                run_in_chroot "grub-install --target=i386-pc /dev/sda --recheck && grub-mkconfig -o /boot/grub/grub.cfg"
            fi
            ;;
        debian|ubuntu)
            if [ "$BOOT_MODE" = "UEFI" ]; then
                run_in_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux --no-nvram --recheck"
                run_in_chroot "cp -f /boot/efi/EFI/Linux/grubx64.efi /boot/efi/EFI/Boot/bootx64.efi || true"
                run_in_chroot "update-grub"
            else
                run_in_chroot "grub-install --target=i386-pc /dev/sda --recheck && update-grub"
            fi
            ;;
        fedora|opensuse*|suse)
            if [ "$BOOT_MODE" = "UEFI" ]; then
                run_in_chroot "grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux --no-nvram --recheck"
                run_in_chroot "cp -f /boot/efi/EFI/Linux/grubx64.efi /boot/efi/EFI/Boot/bootx64.efi || true"
                run_in_chroot "grub2-mkconfig -o /boot/grub2/grub.cfg"
            else
                run_in_chroot "grub2-install --target=i386-pc /dev/sda --recheck && grub2-mkconfig -o /boot/grub2/grub.cfg"
            fi
            ;;
        nixos)
            run_in_chroot "nixos-rebuild boot"
            ;;
        *)
            echo -e "${RED}Distro no soportada automáticamente.${RESET}"
            ;;
    esac

    echo -e "${GREEN}Reparación de GRUB completada.${RESET}"
}


monitor_repair() {
  echo -e "${CYAN}${T[gpu_note]}${RESET}"
  if ! mountpoint -q /mnt; then
    echo -e "${YELLOW}Mount root first via GRUB module to proceed.${RESET}"
    pause; return
  fi
  # Wayland/Hyprland (reset per-user monitor* files)
  find /mnt/home -maxdepth 2 -type f -path "*/.config/monitor*" -print -exec rm -f {} \; 2>/dev/null || true
  # Common: hyprland.conf outputs
  find /mnt/home -maxdepth 3 -type f -path "*/.config/hypr/*.conf" -print -exec sed -i '/^monitor.*/d' {} \; 2>/dev/null || true
  # Xorg
  chroot /mnt /bin/bash -c 'rm -f /etc/X11/xorg.conf /etc/X11/xorg.conf.d/*monitor*.conf 2>/dev/null || true'
  echo -e "${GREEN}${T[done]}${RESET}"
  pause
}

regen_initramfs() {
  if ! mountpoint -q /mnt; then echo -e "${YELLOW}Mount root first via GRUB module to proceed.${RESET}"; pause; return; fi
  if [[ -f /mnt/etc/os-release ]]; then
    . /mnt/etc/os-release
    case "$ID" in
      arch|endeavouros|cachyos) chroot /mnt /bin/bash -c 'mkinitcpio -P' ;;
      debian|ubuntu|linuxmint|pop) chroot /mnt /bin/bash -c 'update-initramfs -u -k all' ;;
      fedora|opensuse*|suse) chroot /mnt /bin/bash -c 'dracut --regenerate-all --force' ;;
      nixos) chroot /mnt /bin/bash -c 'nixos-rebuild boot || true' ;;
      *) echo -e "${RED}Unsupported distro for initramfs.${RESET}" ;;
    esac
  fi
  echo -e "${GREEN}${T[initramfs_done]}${RESET}"
  pause
}

reinstall_kernel() {
  echo -e "${CYAN}${T[kernel_note]}${RESET}"
  if ! mountpoint -q /mnt; then echo -e "${YELLOW}Mount root first via GRUB module to proceed.${RESET}"; pause; return; fi
  if [[ -f /mnt/etc/os-release ]]; then
    . /mnt/etc/os-release
    case "$ID" in
      arch|endeavouros|cachyos) chroot /mnt /bin/bash -c 'pacman -Sy --noconfirm linux || true; mkinitcpio -P || true' ;;
      debian|ubuntu|linuxmint|pop) chroot /mnt /bin/bash -c 'apt-get update && apt-get install -y --reinstall linux-image-generic || true; update-initramfs -u -k all || true' ;;
      fedora) chroot /mnt /bin/bash -c 'dnf -y reinstall kernel-core || true; dracut --regenerate-all --force || true' ;;
      opensuse*|suse) chroot /mnt /bin/bash -c 'zypper -n in -f kernel-default || true; dracut --regenerate-all --force || true' ;;
      nixos) chroot /mnt /bin/bash -c 'nixos-rebuild boot || true' ;;
      *) echo -e "${RED}Unsupported distro for kernel reinstall.${RESET}" ;;
    esac
  fi
  echo -e "${GREEN}${T[done]}${RESET}"
  pause
}

update_system() {
  echo -e "${YELLOW}=== ${T[update_title]} ===${RESET}"
  echo -e "${YELLOW}${T[update_warn]}${RESET}"
  if ! mountpoint -q /mnt; then echo -e "${YELLOW}Mount root first via GRUB module to proceed.${RESET}"; pause; return; fi
  echo -e "${CYAN}${T[updating]}${RESET}"
  if [[ -f /mnt/etc/os-release ]]; then
    . /mnt/etc/os-release
    case "$ID" in
      arch|endeavouros|cachyos) chroot /mnt /bin/bash -c 'pacman -Syu --noconfirm' ;;
      debian|ubuntu|linuxmint|pop) chroot /mnt /bin/bash -c 'apt-get update && apt-get dist-upgrade -y' ;;
      fedora) chroot /mnt /bin/bash -c 'dnf -y upgrade --refresh' ;;
      opensuse*|suse) chroot /mnt /bin/bash -c 'zypper -n refresh && zypper -n dup --allow-vendor-change' ;;
      nixos) chroot /mnt /bin/bash -c 'nixos-rebuild switch --upgrade || nixos-rebuild boot --upgrade || true' ;;
      *) echo -e "${RED}Unsupported distro for update.${RESET}" ;;
    esac
  fi
  echo -e "${GREEN}${T[done]}${RESET}"
  pause
}

boot_freedom() {
  if ! mountpoint -q /mnt; then echo -e "${YELLOW}Mount root first via GRUB module to proceed.${RESET}"; pause; return; fi
  while true; do
    echo -e "${YELLOW}=== ${T[bootcfg_title]} ===${RESET}"
    echo "${T[bc1]}"
    echo "${T[bc2]}"
    echo "${T[bc3]}"
    echo "${T[bc4]}"
    echo "${T[bc5]}"
    local c; read -r -p ">> " c </dev/tty
    case "$c" in
      1)
        local t; read_tty "${T[enter_timeout]}" t
        sed -i "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$t/" /mnt/etc/default/grub || echo "GRUB_TIMEOUT=$t" >> /mnt/etc/default/grub
        regen_grub_cfg_in_chroot
        echo -e "${GREEN}${T[updated]}${RESET}"
        ;;
      2)
        local d; read_tty "${T[enter_default]}" d
        # Escape quotes if present
        d=${d//\"/\\\"}
        sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$d\"/" /mnt/etc/default/grub || echo "GRUB_DEFAULT=\"$d\"" >> /mnt/etc/default/grub
        regen_grub_cfg_in_chroot
        echo -e "${GREEN}${T[updated]}${RESET}"
        ;;
      3)
        enable_os_prober
        regen_grub_cfg_in_chroot
        echo -e "${GREEN}${T[updated]}${RESET}"
        ;;
      4)
        manage_efi_entries
        ;;
      5) break ;;
      *) echo -e "${RED}${T[invalid_sel]}${RESET}" ;;
    esac
  done
}

enable_os_prober() {
  # Ensure os-prober is enabled
  if ! grep -q '^GRUB_DISABLE_OS_PROBER=false' /mnt/etc/default/grub 2>/dev/null; then
    echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub
  fi
  # Some distros need the package
  if chroot /mnt /bin/bash -c 'command -v os-prober' >/dev/null 2>&1; then
    :
  else
    if [[ -f /mnt/etc/os-release ]]; then
      . /mnt/etc/os-release
      case "$ID" in
        arch|endeavouros|cachyos)
          chroot /mnt /bin/bash -c 'pacman -Sy --noconfirm os-prober'
          ;;
        debian|ubuntu|linuxmint|pop)
          chroot /mnt /bin/bash -c 'apt-get update && apt-get install -y os-prober'
          ;;
        fedora)
          chroot /mnt /bin/bash -c 'dnf -y install os-prober' || true
          ;;
        opensuse*|suse)
          chroot /mnt /bin/bash -c 'zypper -n in os-prober' || true
          ;;
      esac
    fi
  fi
}

regen_grub_cfg_in_chroot() {
  if [[ -f /mnt/etc/os-release ]]; then
    . /mnt/etc/os-release
    case "$ID" in
      arch|endeavouros|cachyos) chroot /mnt /bin/bash -c 'grub-mkconfig -o /boot/grub/grub.cfg' ;;
      debian|ubuntu|linuxmint|pop) chroot /mnt /bin/bash -c 'update-grub' ;;
      fedora|opensuse*|suse) chroot /mnt /bin/bash -c 'grub2-mkconfig -o /boot/grub2/grub.cfg' ;;
      nixos) chroot /mnt /bin/bash -c 'nixos-rebuild boot || true' ;;
    esac
  fi
}

manage_efi_entries() {
  if [[ ! -d /sys/firmware/efi ]]; then echo -e "${YELLOW}EFI not available (BIOS mode).${RESET}"; pause; return; fi
  if ! command -v efibootmgr &>/dev/null; then echo -e "${YELLOW}efibootmgr not found on live environment.${RESET}"; pause; return; fi
  while true; do
    echo -e "${CYAN}${T[efimenu]}${RESET}"
    local o; read -r -p ">> " o </dev/tty
    case "$o" in
      1) efibootmgr; pause ;;
      2)
        local ord; read_tty "${T[enter_order]}" ord
        efibootmgr -o "$ord" || true
        ;;
      3)
        local bn; read_tty "${T[enter_bootnext]}" bn
        efibootmgr -n "$bn" || true
        ;;
      4) break ;;
      *) echo -e "${RED}${T[invalid_sel]}${RESET}" ;;
    esac
  done
}

diagnostics() {
  echo -e "${YELLOW}=== ${T[diag_title]} ===${RESET}"
  echo -e "${CYAN}CPU/GPU:${RESET}"; lscpu | sed -n '1,5p' || true
  echo -e "${CYAN}PCI GPUs:${RESET}"; lspci | grep -Ei 'vga|3d|display' || true
  echo -e "${CYAN}Disks:${RESET}"; lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT | sed 's/^/  /'
  echo -e "${CYAN}EFI vars present:${RESET}"; [[ -d /sys/firmware/efi/efivars ]] && echo yes || echo no
  echo -e "${CYAN}Secure Boot:${RESET} $(secure_boot_status)"
  if command -v journalctl &>/dev/null; then
    echo -e "${CYAN}Last boot errors (prev boot):${RESET}"
    journalctl -b -1 -p err --no-pager 2>/dev/null | tail -n 20 || true
  fi
  pause
}

settings_menu() {
  while true; do
    echo -e "${YELLOW}=== ${T[settings_title]} ===${RESET}"
    echo "${T[set_lang]}"
    echo "${T[set_expert]}"
    echo "${T[set_install]}"
    echo "${T[set_uninstall]}"
    echo "5) Update boot-repair GIT (UNDER IN PROCESS)"
    echo "6) Update boot-repair AUR"
    echo "${T[back]}"
    local c; read -r -p ">> " c </dev/tty
    case "$c" in
      1)
        case "$LANG_CODE" in
          es) LANG=es ;;
          en) LANG=de ;;
          de) LANG=pt ;;
          *) LANG=en ;;
        esac
        exec "$0"
        ;;
      2)
        if $EXPERT; then EXPERT=false; echo -e "${GREEN}${T[expert_off]}${RESET}"; else EXPERT=true; echo -e "${GREEN}${T[expert_on]}${RESET}"; fi
        ;;
      3)
        if [[ -f /usr/local/bin/bootrepair ]]; then
          echo -e "${YELLOW}${T[already_alias]}${RESET}"
        else
          cp "$0" /usr/local/bin/bootrepair
          chmod +x /usr/local/bin/bootrepair
          echo -e "${GREEN}${T[installed_alias]}${RESET}"
        fi
        ;;
      4)
        if [[ -f /usr/local/bin/bootrepair ]]; then
          rm -f /usr/local/bin/bootrepair
          echo -e "${GREEN}${T[uninstalled_alias]}${RESET}"
        else
          echo -e "${YELLOW}${T[no_alias]}${RESET}"
        fi
        ;;
      5)
        REPO_DIR="$HOME/boot-repair"
        REPO_URL="https://github.com/AndresDev859674/boot-repair.git"

        if [[ -d "$REPO_DIR/.git" ]]; then
          echo -e "${YELLOW}Updating existing repository...${RESET}"
          cd "$REPO_DIR" || { echo "Error: could not enter $REPO_DIR"; break; }
          git pull
        else
          echo -e "${YELLOW}Cloning repository...${RESET}"
          git clone "$REPO_URL" "$REPO_DIR"
          cd "$REPO_DIR" || { echo "Error: could not enter $REPO_DIR"; break; }
        fi

        chmod +x boot-repair.sh
        echo -e "${GREEN}Running boot-repair.sh as administrator...${RESET}"
        sudo ./boot-repair.sh

        break
        ;;
      6)
        echo -e "${RED}Just for update use a other Command Line and put the next command : yay -S boot-repair-andres ${RESET}"
        pause
        ;;
      7) break ;;
      *) echo -e "${RED}${T[invalid_sel]}${RESET}" ;;
    esac
  done
}

alias_menu() {
  while true; do
      echo -e "${CYAN}"
  cat << "EOF"
 __  __                                         ___                           
/\ \/\ \          __                           /\_ \    __                    
\ \ \ \ \    ____/\_\    ___      __       __  \//\ \  /\_\     __      ____  
 \ \ \ \ \  /',__\/\ \ /' _ `\  /'_ `\   /'__`\  \ \ \ \/\ \  /'__`\   /',__\ 
  \ \ \_\ \/\__, `\ \ \/\ \/\ \/\ \L\ \ /\ \L\.\_ \_\ \_\ \ \/\ \L\.\_/\__, `\
   \ \_____\/\____/\ \_\ \_\ \_\ \____ \\ \__/.\_\/\____\\ \_\ \__/.\_\/\____/
    \/_____/\/___/  \/_/\/_/\/_/\/___L\ \\/__/\/_/\/____/ \/_/\/__/\/_/\/___/ 
                                  /\____/                                     
                                  \_/__/  
EOF
  echo -e "${RESET}"
  echo -e "${YELLOW}=== Using Alias / Tutorial ===${RESET}"
    echo "Quick flags: -grub -monitor -initramfs -kernel -diag -update -bootcfg -auto"
    echo "Secret flags (These are not in the main menu, they may be unstable or something else, BE CAREFUL):"
    echo "-grub-experimental"
    echo "These are to go faster without selections"
    echo ''
    echo 'What is this?'
    echo 'Simple, just use sudo ./boot-repair.sh or sudo boot-repair and add a -string for example -update'
    echo ''
    echo 'Write exit to test or just exit'
    local c; read -r -p ">> " c </dev/tty
    case "$c" in
    exit) break ;;
    esac
  done
}

changelog_menu() {
  while true; do
      echo -e "${CYAN}"
  cat << "EOF"
.---------------------------------------------------------------------.
|     ___           ___           ___           ___           ___     |
|    /\  \         /\__\         /\  \         /\__\         /\  \    |
|   /::\  \       /:/  /        /::\  \       /::|  |       /::\  \   |
|  /:/\:\  \     /:/__/        /:/\:\  \     /:|:|  |      /:/\:\  \  |
| /:/  \:\  \   /::\  \ ___   /::\~\:\  \   /:/|:|  |__   /:/  \:\  \ |
|/:/__/ \:\__\ /:/\:\  /\__\ /:/\:\ \:\__\ /:/ |:| /\__\ /:/__/_\:\__\|
|\:\  \  \/__/ \/__\:\/:/  / \/__\:\/:/  / \/__|:|/:/  / \:\  /\ \/__/|
| \:\  \            \::/  /       \::/  /      |:/:/  /   \:\ \:\__\  |
|  \:\  \           /:/  /        /:/  /       |::/  /     \:\/:/  /  |
|   \:\__\         /:/  /        /:/  /        /:/  /       \::/  /   |
|    \/__/         \/__/         \/__/         \/__/         \/__/    |
|     ___           ___       ___           ___                       |
|    /\  \         /\__\     /\  \         /\  \                      |
|   /::\  \       /:/  /    /::\  \       /::\  \                     |
|  /:/\:\  \     /:/  /    /:/\:\  \     /:/\:\  \                    |
| /::\~\:\  \   /:/  /    /:/  \:\  \   /:/  \:\  \                   |
|/:/\:\ \:\__\ /:/__/    /:/__/ \:\__\ /:/__/_\:\__\                  |
|\:\~\:\ \/__/ \:\  \    \:\  \ /:/  / \:\  /\ \/__/                  |
| \:\ \:\__\    \:\  \    \:\  /:/  /   \:\ \:\__\                    |
|  \:\ \/__/     \:\  \    \:\/:/  /     \:\/:/  /                    |
|   \:\__\        \:\__\    \::/  /       \::/  /                     |
|    \/__/         \/__/     \/__/         \/__/                      |
'---------------------------------------------------------------------'
EOF
  echo -e "${RESET}"
  echo -e "${YELLOW}=== Changelog ===${RESET}"
    echo "Changelog, Current version 1.0 (COMPLETE VERSION)"
    echo ''
    echo "Added :"
    echo 'test lol'
    echo ''
    echo 'Write exit to exit'
    local c; read -r -p ">> " c </dev/tty
    case "$c" in
    exit) break ;;
    esac
  done
}


#-----------------------
# Menu
#-----------------------
main_menu() {
  while true; do
    clear
    ascii_banner
    info_header
    echo -e "${YELLOW}=== ${T[menu_title]} ===${RESET}"
    echo ""
    echo "The LANG is been removed! Learn english!"
    echo ""
    echo "${T[m1]}"
    echo "${T[m2]}"
    echo "${T[m3]}"
    echo "${T[m4]}"
    echo "${T[m5]}"
    echo "${T[m6]}"
    echo "${T[m7]}"
    echo "${T[m8]}"
    echo "9) Aliases (Only for Git)"
    echo "${T[m9]}"
    local choice; read -r -p "${T[enter_choice]} >> " choice </dev/tty
    case "$choice" in
      1) grub_repair ;;
      2) monitor_repair ;;
      3) regen_initramfs ;;
      4) reinstall_kernel ;;
      5) update_system ;;
      6) boot_freedom ;;
      7) diagnostics ;;
      8) settings_menu ;;
      9) alias_menu ;;
      10) break ;;
      *) echo -e "${RED}${T[invalid_sel]}${RESET}"; sleep 1 ;;
    esac
  done
}


#-----------------------
# Entry / CLI flags
#-----------------------
need_root

# Quick flags: -grub, -monitor, -initramfs, -kernel, -diag, -update, -bootcfg, -auto
case "${1:-}" in
  -grub) grub_repair; exit 0 ;;
  -monitor) monitor_repair; exit 0 ;;
  -initramfs) regen_initramfs; exit 0 ;;
  -kernel) reinstall_kernel; exit 0 ;;
  -diag) diagnostics; exit 0 ;;
  -update) update_system; exit 0 ;;
  -bootcfg) boot_freedom; exit 0 ;;
  -aliases) alias_menu; exit 0 ;;
  -grub-experimental) grub_repair_experimental; exit 0 ;;
  -changelog) changelog_menu; exit 0 ;;
  -auto)
    # Fire-and-forget: try to auto-repair GRUB with defaults
    auto_detect_parts >/tmp/bootrepair_auto 2>/dev/null || true
    source /tmp/bootrepair_auto 2>/dev/null || true
    if [[ -n "${ROOT:-}" ]]; then
      prepare_chroot "$ROOT" "${EFI:-}"
      grub_repair
    else
      main_menu
    fi
    exit 0
    ;;
esac

main_menu

#-----------------------
# Footer
#-----------------------
END_TIME=$(date +%s) 
DURATION=$((END_TIME - START_TIME))

#!/bin/bash

echo -e "${BLUE}"
# Carpeta donde guardaste los ASCII
CARPETA="./art"

# Elegir un archivo aleatorio de la carpeta
archivo=$(ls "$CARPETA" | shuf -n 1)
# Mostrarlo con cat
cat "$CARPETA/$archivo"

echo ""
echo -e "${RESET}${CYAN}${T[done]}${RESET}" 
echo -e "${YELLOW}${T[total_time]}: ${DURATION}s${RESET}"
echo -e "${BLUE} To Reboot write (sudo reboot)"
