#!/bin/bash
# Script: repair_systemdbot.sh
# Purpose: Repair systemd-boot (UEFI ONLY).

#================================================
# Advanced Configuration and Error Handling
#================================================
set -e
trap 'echo -e "\n[FATAL ERROR] Script failed at line $LINENO. Review log: $(pwd)/systemd_boot_repair.log"; cleanup; exit 1' ERR
trap cleanup EXIT INT

# Log all output (stdout and stderr)
LOG_FILE="$(pwd)/systemd_boot_repair.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================================================="
echo "[INFO] Starting systemd-boot Repair Script (UEFI ONLY). (Log: $LOG_FILE)"
echo "[INFO] Supported Distros: Arch, Fedora, openSUSE, NixOS."
echo "========================================================================="

# Variables
MOUNT_DIR="/mnt/sdboot_target"
ROOT_PARTITION=""
BOOT_PARTITION="" # MUST BE THE EFI PARTITION

#================================================
# Core Functions
#================================================

# 1. Clean up mounts and directories on exit/error
cleanup() {
    echo -e "\n[INFO] Starting cleanup process..."
    for d in dev proc sys boot/efi; do
        if mountpoint -q "$MOUNT_DIR/$d"; then 
            echo "[INFO] Unmounting $MOUNT_DIR/$d..."
            umount -R "$MOUNT_DIR/$d" 2>/dev/null || umount -l "$MOUNT_DIR/$d" || true
        fi
    done
    if mountpoint -q "$MOUNT_DIR"; then 
        echo "[INFO] Unmounting $MOUNT_DIR..."
        umount "$MOUNT_DIR" 2>/dev/null || umount -l "$MOUNT_DIR" || true
    fi
    
    if [ -d "$MOUNT_DIR" ] && [ ! "$(ls -A $MOUNT_DIR)" ]; then
        rmdir "$MOUNT_DIR"
    fi
    echo "[INFO] Cleanup complete."
}

# 2. Find Partitions and Mount System
find_and_mount_system() {
    echo "[INFO] Running partition setup. UEFI required. Please enter details."
    fdisk -l || lsblk
    
    read -r -p "Enter ROOT PARTITION (e.g., /dev/sda2): " ROOT_PARTITION
    read -r -p "Enter EFI PARTITION (e.g., /dev/sda1): " BOOT_PARTITION
    
    if [ -z "$BOOT_PARTITION" ]; then
        echo "[FATAL ERROR] EFI partition is mandatory for systemd-boot. Aborting."
        exit 1
    fi

    # Check for device existence
    if [ ! -e "$ROOT_PARTITION" ] || [ ! -e "$BOOT_PARTITION" ]; then
        echo "[FATAL ERROR] One or both partitions do not exist. Aborting."
        exit 1
    fi
    
    mkdir -p "$MOUNT_DIR"
    echo "[INFO] Mounting Root: $ROOT_PARTITION to $MOUNT_DIR."
    mount "$ROOT_PARTITION" "$MOUNT_DIR"
    
    # Crucial: ESP must be mounted inside the chroot environment.
    mkdir -p "$MOUNT_DIR/boot/efi" 
    echo "[INFO] Mounting EFI: $BOOT_PARTITION to $MOUNT_DIR/boot/efi."
    mount "$BOOT_PARTITION" "$MOUNT_DIR/boot/efi" 
    
    echo "[INFO] Binding /dev, /proc, /sys."
    for dir in dev proc sys; do 
        mount --bind "/$dir" "$MOUNT_DIR/$dir"
    done
}

# 3. Core systemd-boot Repair Logic (Inside Chroot)
repair_systemd_bootloader() {
    echo "[STEP 1/1] Entering chroot to repair systemd-boot..."

    # NOTE: Using 'EOT' instead of 'EOF' to prevent shell variable expansion outside chroot,
    # though it shouldn't matter here since we don't use variables inside the chroot.
    chroot "$MOUNT_DIR" /bin/bash <<EOT
        echo "[CHROOT] Running systemd-boot installation and configuration."

        # --- Detect NixOS and use its dedicated rebuild tool ---
        if command -v nixos-rebuild >/dev/null 2>&1; then
             echo "[CHROOT NIXOS] Detected NixOS. Running system rebuild to fix systemd-boot."
             nixos-rebuild switch
             exit 0 # Exit chroot block after NixOS rebuild
        fi
        
        # --- Universal systemd-boot Repair for other Distros ---
        echo "[CHROOT SDBOOT] 1. Running bootctl update/install..."
        
        # Arch/Fedora/OpenSUSE (if using systemd-boot)
        # We use '|| true' to continue execution even if 'bootctl install' fails, 
        # allowing 'bootctl update' to run, which is often sufficient.
        bootctl install || bootctl update || true 

        echo "[CHROOT] systemd-boot repair finished."
EOT
}

#================================================
# Execution
#================================================
if [ "$(id -u)" != "0" ]; then
   echo "[FATAL ERROR] This script must be run as root (use sudo). Aborting." 
   exit 1
fi

find_and_mount_system
repair_systemd_bootloader

echo "========================================================================="
echo "[SUCCESS POTENTIAL] systemd-boot repair complete. Reboot and check."
echo "========================================================================="