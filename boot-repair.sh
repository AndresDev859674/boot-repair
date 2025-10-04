#!/usr/bin/env bash
#========================================================
#  BootRepair v0.1.2
#  License: MIT
#  Description: Swiss-army live rescue tool: GRUB repair, display reset,
#               initramfs, kernel, system update, boot freedom, diagnostics.
#  Supports: Arch/EndeavourOS/CachyOS, Debian/Ubuntu/Mint/Pop, Fedora,
#            openSUSE, NixOS (best-effort)
#========================================================

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
  T[m2]="3) Reset monitor configs (Wayland/Hyprland/Xorg)"
  T[m3]="4) Regenerate initramfs"
  T[m4]="5) Reinstall kernel"
  T[m5]="6) Update operating system"
  T[m6]="7) Boot freedom (timeout, default, EFI, os-prober)"
  T[m7]="8) Quick diagnostics"
  T[m8]="9) Settings (language, expert mode, install alias)"
  T[m9]="11) Exit"
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
  echo -e "${YELLOW}=== ${T[title]} v0.1.2 ===${RESET}"
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

echo ""

# T[] is assumed to be defined by the main script, but for a standalone script:
declare -A T

T[gather]="DETAILED SYSTEM INFORMATION 🔎"
T[detected_arch]="Architecture"
T[detected_distro]="Distribution"
T[detected_mode]="Boot Mode"
T[secureboot]="Secure Boot"

# Mock function for secure_boot_status (replace with your actual implementation if needed)
secure_boot_status() {
    if command -v mokutil &>/dev/null; then
        mokutil --sb-state 2>/dev/null | grep "SecureBoot" | awk '{print $NF}'
    elif [[ -f /sys/firmware/efi/efivars/SecureBoot-*-*-*-*-* ]]; then
        echo "Enabled"
    else
        echo "Disabled/Not Supported"
    fi
}

info_header() {
    echo -e "${CYAN}${T[gather]}${RESET}"
    echo "------------------------------------------------"

    ## 1. General & OS Information
    echo -e "${YELLOW}>> General & OS Info${RESET}"
    echo "  Hostname:           $(hostname)"
    echo "  Current User:       $(whoami)"
    echo "  Uptime:             $(uptime -p | cut -d' ' -f2-)"
    echo "  Date/Time:          $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Current Shell:      $SHELL"
    echo "  Kernel:             $(uname -r)"

    # OS Distribution Detail
    DISTRO_NAME="Unknown"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_NAME="$PRETTY_NAME"
    elif command -v lsb_release &>/dev/null; then
        DISTRO_NAME=$(lsb_release -ds)
    fi
    echo -e "  ${T[detected_distro]}:    ${GREEN}$DISTRO_NAME${RESET}"

    # Architecture and Boot Mode
    ARCH=$(uname -m)
    echo "  ${T[detected_arch]}:         $ARCH"
    if [[ -d /sys/firmware/efi/efivars ]]; then BOOT_MODE="UEFI"; else BOOT_MODE="BIOS"; fi
    echo -e "  ${T[detected_mode]}:    ${GREEN}$BOOT_MODE${RESET}"
    echo -e "  ${T[secureboot]}:       ${GREEN}$(secure_boot_status)${RESET}"
    echo "------------------------------------------------"

    ## 2. Processor (CPU) Information
echo -e "${YELLOW}>> Processor (CPU) Info${RESET}"
if command -v lscpu &>/dev/null; then
    # --- MÉTODO ROBUSTO: LECTURA DIRECTA DE LÍNEAS CON 'grep' ---

# --- MÉTODO ROBUSTO: LECTURA DIRECTA DE /proc/cpuinfo y lscpu ---

    # 1. Modelo de CPU (el más seguro, lee cpuinfo)
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | awk -F': ' '{print $2}' | xargs)

    # 2. Otros datos (usamos lscpu por su formato conciso)
    CPU_CORES=$(lscpu | grep "^CPU(s):" | awk '{print $2}' | xargs)
    CPU_THREADS_PER_CORE=$(lscpu | grep "Thread(s) per core:" | awk '{print $4}' | xargs)
    CPU_SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}' | xargs)

    echo "  Model:              ${CPU_MODEL:-N/A}"
    echo "  Cores (Total):      ${CPU_CORES:-N/A}"
    echo "  Threads/Core:       ${CPU_THREADS_PER_CORE:-N/A}"
    echo "  Sockets:            ${CPU_SOCKETS:-N/A}"
else
    echo "  lscpu command not found."
fi
echo "------------------------------------------------"


    ## 3. Memory (RAM) Information
    echo -e "${YELLOW}>> Memory (RAM) Info${RESET}"
    if command -v free &>/dev/null; then
        MEM_TOTAL=$(free -h | grep "Mem:" | awk '{print $2}')
        MEM_USED=$(free -h | grep "Mem:" | awk '{print $3}')
        MEM_FREE=$(free -h | grep "Mem:" | awk '{print $4}')
        MEM_USED_PERCENT=$(free | awk '/Mem:/ {printf "%.2f", $3/$2*100}')

        echo "  Total RAM:          $MEM_TOTAL"
        echo "  Used RAM:           $MEM_USED (${RED}$MEM_USED_PERCENT%${RESET})"
        echo "  Free RAM:           $MEM_FREE"

        # Optional: Swap info
        SWAP_TOTAL=$(free -h | grep "Swap:" | awk '{print $2}')
        SWAP_USED=$(free -h | grep "Swap:" | awk '{print $3}')
        echo "  Total SWAP:         $SWAP_TOTAL (Used: $SWAP_USED)"
    else
        echo "  free command not found."
    fi
    echo "------------------------------------------------"

    # 4. Disk Usage
    echo -e "${YELLOW}>> Disk Usage${RESET}"
    if command -v df &>/dev/null; then
        # ... (código de df -h)

# Mostrar el uso de las particiones principales (raíz y /home si existe)
    echo "  Root Partition Usage:"
    df -h / | grep -v Filesystem | awk '{printf "    Size: %s | Used: %s | Avail: %s | Used %%: %s\n", $2, $3, $4, $5}'

    # Mostrar particiones adicionales relevantes (como /home, /var, etc.)
    echo "  Other Mounted Filesystems:"
    df -h -x tmpfs -x devtmpfs | grep -E '^/dev' | grep -v ' / ' | column -t
    fi
    echo "------------------------------------------------"

    ## 5. Network Information
    echo -e "${YELLOW}>> Network Info${RESET}"
    if command -v ip &>/dev/null; then
        # Get the primary interface (excluding loopback)
        MAIN_IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')

        if [ -n "$MAIN_IFACE" ]; then
            IP_ADDR=$(ip a show dev "$MAIN_IFACE" | grep 'inet ' | awk '{print $2}' | head -n 1)
            MAC_ADDR=$(ip link show dev "$MAIN_IFACE" | grep 'link/ether' | awk '{print $2}')

            echo "  Primary Interface:  $MAIN_IFACE"
            echo "  IP Address:         $IP_ADDR"
            echo "  MAC Address:        $MAC_ADDR"

            # Show active listening ports
            echo "  Listening Ports (TCP/UDP):"
            if command -v ss &>/dev/null; then
                ss -tuln | head -n 6 # Show a sample of 5 listening ports
            else
                echo "    (Use 'ss -tuln' for full list)"
            fi
        else
            echo "  No active network interfaces detected."
        fi
    else
        echo "  ip command not found."
    fi
    echo "------------------------------------------------"
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
# --- Cleanup Function ---
# Ensures all partitions are safely unmounted upon script completion or in case of an error.
cleanup() {
    # Prevent the exit trap from running multiple times
    trap - EXIT
    echo -e "\n${CYAN}>>> Cleaning up and unmounting partitions...${RESET}"
    # Recursively unmount everything under /mnt. It's safer and more effective.
    if mountpoint -q /mnt; then
        echo "  Unmounting /mnt recursively..."
        sudo umount -R /mnt &>/dev/null
    fi
    echo -e "${GREEN}>>> Cleanup complete.${RESET}"
}

# --- Help Function ---
# Displays how to use the script.
show_usage() {
    echo -e "${BOLD}Usage:${RESET} sudo bash $0"
    echo -e "This script must be run with superuser (root) privileges."
    exit 1
}

# --- Main Repair Function ---
grub_repair() {
    # Set a trap to call cleanup() on script exit, interruption, or termination.
    trap cleanup EXIT INT TERM

    # --- 1. Initial Checks ---
    echo -e "${BLUE}${BOLD}--- GRUB Advanced Repair Tool ---${RESET}"

    # Check if running as root
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}Error: This script requires superuser privileges.${RESET}"
        show_usage
    fi

    # Check for necessary dependencies
    for cmd in lsblk mount umount chroot grub-install; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}Error: Required command '${BOLD}$cmd${RESET}${RED}' not found. Please install it.${RESET}"
            exit 1
        fi
    done
    echo -e "${GREEN}All necessary dependencies are present.${RESET}"

    # --- 2. System Detection ---
    echo -e "\n${CYAN}>>> Detecting system configuration...${RESET}"

    # Detect architecture
    local arch
    arch=$(uname -m)
    local grub_target_arch=""
    case "$arch" in
        "x86_64")   grub_target_arch="x86_64" ;;
        "i386"|"i686") grub_target_arch="i386" ;;
        "aarch64")  grub_target_arch="arm64" ;;
        "armv7l"|"armv6l") grub_target_arch="arm" ;;
        *)
            echo -e "${RED}Error: Unsupported architecture ('${BOLD}$arch${RESET}${RED}').${RESET}"
            exit 1
            ;;
    esac
    echo -e "  ${GREEN}Architecture detected:${RESET} $arch"

    # Detect boot mode (UEFI or BIOS)
    local boot_mode=""
    if [ -d /sys/firmware/efi/efivars ]; then
        boot_mode="UEFI"
    else
        boot_mode="BIOS"
    fi
    echo -e "  ${GREEN}Boot mode detected:${RESET} $boot_mode"

    # --- 3. Partition Selection ---
    echo -e "\n${CYAN}>>> Partition Selection ---${RESET}"
    echo "1) Automatic detection"
    echo "2) Manual selection"
    local selection_mode
    read -rp "Choose a mode [1/2]: " selection_mode

    local root_part=""
    local efi_part=""

    if [[ "$selection_mode" == "2" ]]; then
        # --- Manual Mode ---
        echo -e "\n${YELLOW}Listing available disks and partitions:${RESET}"
        lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
        echo -e "${YELLOW}Please identify your partitions (e.g., /dev/sda2).${RESET}"

        read -rp "Enter your root (/) partition: " root_part
        if [[ "$boot_mode" == "UEFI" ]]; then
            read -rp "Enter your EFI (ESP) partition: " efi_part
        fi
    else
        # --- Automatic Mode ---
        echo -e "\n${YELLOW}Searching for partitions automatically...${RESET}"

# Detect EFI partition (ESP)
        if [[ "$boot_mode" == "UEFI" ]]; then
            # Searches for partitions with the 'EFI System Partition' PARTTYPE GUID
            local esp_candidates
            esp_candidates=($(lsblk -pno NAME,PARTTYPE | awk '$2=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print $1}'))
            if [ ${#esp_candidates[@]} -eq 0 ]; then
                echo -e "${RED}Error: No EFI System Partition (ESP) found. Try manual mode.${RESET}"
                exit 1
            elif [ ${#esp_candidates[@]} -eq 1 ]; then
                efi_part=${esp_candidates[0]}
                echo -e "  ${GREEN}EFI partition found:${RESET} $efi_part"
            else
                echo -e "${YELLOW}Multiple EFI partitions found. Please choose one:${RESET}"
                select opt in "${esp_candidates[@]}"; do
                    if [[ -n "$opt" ]]; then
                        efi_part=$opt
                        break
                    else
                        echo "Invalid selection."
                    fi
                done
            fi
        fi

        # List Linux partitions for the user to choose the root
        echo -e "${YELLOW}Please select your root (/) partition from the list:${RESET}"
        # Show partitions with common Linux filesystems
        local root_candidates
        root_candidates=($(lsblk -pno NAME,FSTYPE | awk '$2 ~ /ext4|btrfs|xfs|f2fs/ {print $1}'))
        if [ ${#root_candidates[@]} -eq 0 ]; then
            echo -e "${RED}Error: No partitions with common Linux filesystems found. Try manual mode.${RESET}"
            exit 1
        fi

        select opt in "${root_candidates[@]}"; do
            if [[ -n "$opt" ]]; then
                root_part=$opt
                break
            else
                echo "Invalid selection."
            fi
        done
    fi

    # Validate that selected partitions exist as block devices
    if ! [ -b "$root_part" ] || ([[ "$boot_mode" == "UEFI" ]] && ! [ -b "$efi_part" ]); then
        echo -e "${RED}Error: One or more selected partitions are not valid block devices.${RESET}"
        exit 1
    fi

    # --- 4. Confirmation and Mounting ---
    echo -e "\n${CYAN}>>> Operation Summary ---${RESET}"
    echo -e "  - ${BOLD}Root Partition:${RESET} $root_part"
    if [[ "$boot_mode" == "UEFI" ]]; then
        echo -e "  - ${BOLD}EFI Partition:${RESET}  $efi_part"
    fi
    echo -e "  - ${BOLD}Boot Mode:${RESET}     $boot_mode"
    echo -e "\n${YELLOW}WARNING:${RESET} This will modify your system's bootloader files."
    read -rp "  Do you wish to continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operation cancelled by user.${RESET}"
        exit 0
    fi

    echo -e "\n${CYAN}>>> Mounting the file system...${RESET}"
    echo "  Mounting $root_part on /mnt..."
    sudo mount "$root_part" /mnt
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to mount the root partition.${RESET}"; exit 1;
    else
        echo -e "  ${GREEN}Root partition mounted successfully.${RESET}"
    fi

    if [[ "$boot_mode" == "UEFI" ]]; then
        # Ensure the mount point for EFI exists
        echo "  Creating mountpoint /mnt/boot/efi if it doesn't exist..."
        sudo mkdir -p /mnt/boot/efi
        echo "  Mounting $efi_part on /mnt/boot/efi..."
        sudo mount "$efi_part" /mnt/boot/efi
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to mount the EFI partition.${RESET}"; exit 1;
        else
            echo -e "  ${GREEN}EFI partition mounted successfully.${RESET}"
        fi
    fi

    # --- 5. Preparing the Chroot Environment ---
    echo -e "\n${CYAN}>>> Preparing the chroot environment...${RESET}"
    # Mount virtual filesystems necessary for chroot to function correctly
    echo "  Binding /dev, /proc, and /sys..."
    for fs in dev proc sys; do
        sudo mount --make-rslave --bind /$fs /mnt/$fs
    done
    echo "  Copying DNS info to chroot for internet connectivity..."
    sudo cp /etc/resolv.conf /mnt/etc/resolv.conf
    echo -e "  ${GREEN}Chroot environment is ready.${RESET}"

    # Detect distribution from within the chroot
    local distro=""
    if [ -f /mnt/etc/os-release ]; then
        distro=$(awk -F= '$1=="ID" { print $2 }' /mnt/etc/os-release | tr -d '"')
        echo -e "  ${GREEN}Distribution detected in ${root_part}:${RESET} ${distro^}"
    else
        echo -e "${RED}Error: Could not detect distribution. /etc/os-release not found.${RESET}"
        exit 1
    fi

    # --- 6. Executing the Repair ---
    echo -e "\n${CYAN}>>> Executing GRUB Repair...${RESET}"

    local grub_install_cmd=""
    local grub_config_cmd=""
    local pkg_manager_cmd=""
    local grub_efi_dir="/boot/efi" # Standard in most distros

    # Distribution-specific settings
    case "$distro" in
        arch|endeavouros|manjaro)
            grub_install_cmd="grub-install"
            grub_config_cmd="grub-mkconfig -o /boot/grub/grub.cfg"
            pkg_manager_cmd="pacman -S --noconfirm grub efibootmgr" # Reinstall just in case
            ;;
        debian|ubuntu|linuxmint)
            grub_install_cmd="grub-install"
            grub_config_cmd="update-grub"
            pkg_manager_cmd="apt-get update && apt-get install --reinstall -y grub-common grub-efi-${grub_target_arch}-signed shim-signed"
            ;;
        fedora|centos|rhel)
            grub_install_cmd="grub2-install"
            grub_config_cmd="grub2-mkconfig -o /boot/grub2/grub.cfg"
            pkg_manager_cmd="dnf reinstall -y grub2-efi-${grub_target_arch} shim-${grub_target_arch}"
            ;;
        opensuse*|sles)
            grub_install_cmd="grub2-install"
            grub_config_cmd="grub2-mkconfig -o /boot/grub2/grub.cfg"
            pkg_manager_cmd="zypper install --force grub2-x86_64-efi shim"
            ;;
        *)
            echo -e "${RED}Error: Distribution '${distro}' is not supported by this script.${RESET}"
            exit 1
            ;;
    esac

    local full_command=""
    if [[ "$boot_mode" == "UEFI" ]]; then
        local secure_boot_fix=""
        read -rp "  Attempt to reinstall packages for Secure Boot? (Recommended) [y/N]: " fix_sb
        if [[ "$fix_sb" =~ ^[Yy]$ ]]; then
            secure_boot_fix="$pkg_manager_cmd && "
        fi

        # The bootloader-id is the name that will appear in the BIOS/UEFI boot menu
        full_command="${secure_boot_fix}${grub_install_cmd} --target=${grub_target_arch}-efi --efi-directory=${grub_efi_dir} --bootloader-id=GRUB --recheck && ${grub_config_cmd}"

    else # BIOS Mode
        local target_disk=""
        echo -e "${YELLOW}Please choose the disk to install GRUB onto (usually the main disk, not a partition):${RESET}"
        local disk_candidates
        disk_candidates=($(lsblk -dno NAME | awk '{print "/dev/"$1}'))
        select opt in "${disk_candidates[@]}"; do
            if [[ -n "$opt" ]]; then
                target_disk=$opt
                break
            else
                echo "Invalid selection."
            fi
        done
        full_command="${grub_install_cmd} --target=${grub_target_arch}-pc --recheck ${target_disk} && ${grub_config_cmd}"
    fi

    # Execute the final command inside the chroot
    echo -e "\n${YELLOW}The following commands will be executed inside the chroot:${RESET}"
    echo -e "${BOLD}$full_command${RESET}"
    echo -e "${YELLOW}Starting repair process...${RESET}"

    if sudo chroot /mnt /bin/bash -c "$full_command"; then
        echo -e "\n${GREEN}${BOLD}Success! The GRUB repair process appears to have completed successfully.${RESET}"
        echo -e "You may now reboot your system."
    else
        echo -e "\n${RED}${BOLD}Error: The GRUB repair failed inside the chroot environment.${RESET}"
        echo -e "Please review the error messages above to diagnose the issue."
        exit 1
    fi
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

grub_repair-classic() {
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
    echo "TIP : You can use boot-repair on your PC and then go to the Live user and mount your partitions and chroot and use boot-repair as a repair without installing inside the Live User"
    echo ""
    echo "${T[m1]}"
    echo "2) Repair GRUB Classic (most Stable + Recommended)"
    echo "${T[m2]}"
    echo "${T[m3]}"
    echo "${T[m4]}"
    echo "${T[m5]}"
    echo "${T[m6]}"
    echo "${T[m7]}"
    echo "${T[m8]}"
    echo "10) Aliases (For GIT users Please install it in Settings)"
    echo "${T[m9]}"
    local choice; read -r -p "${T[enter_choice]} >> " choice </dev/tty
    case "$choice" in
      1) grub_repair ;;
      2) grub_repair-classic ;;
      3) monitor_repair ;;
      4) regen_initramfs ;;
      5) reinstall_kernel ;;
      6) update_system ;;
      7) boot_freedom ;;
      8) diagnostics ;;
      9) settings_menu ;;
      10) alias_menu ;;
      11) break ;;
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
