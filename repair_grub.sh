#!/bin/bash
# Script: repair_grub.sh
# Purpose: Repair GRUB2 bootloader installation and configuration.

# Configuration and Error Handling (Generic)
set -e
trap 'echo -e "\n[FATAL ERROR] Script failed at line $LINENO. Review log: $(pwd)/grub_repair.log"; cleanup; exit 1' ERR
trap cleanup EXIT INT
LOG_FILE="$(pwd)/grub_repair.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================================================="
echo "[INFO] Starting GRUB2 Repair Script. (Log: $LOG_FILE)"
echo "[INFO] Supported Distros: Arch, Debian, Ubuntu, Fedora, openSUSE, Gentoo, Alpine, NixOS."
echo "========================================================================="

# Variables
MOUNT_DIR="/mnt/grub_target"
ROOT_PARTITION=""
BOOT_PARTITION=""
DISK_DEVICE=""

# --- Simplified Partition/Mounting Setup (Place your full, robust logic here) ---
find_and_mount_system() {
    echo "[INFO] Running partition setup. Please enter details."
    fdisk -l || lsblk
    read -r -p "Enter ROOT PARTITION (e.g., /dev/sda2): " ROOT_PARTITION
    read -r -p "Enter EFI PARTITION (if any): " BOOT_PARTITION
    read -r -p "Enter MAIN DISK DEVICE (e.g., /dev/sda): " DISK_DEVICE
    
    mkdir -p "$MOUNT_DIR"
    mount "$ROOT_PARTITION" "$MOUNT_DIR"
    if [ -n "$BOOT_PARTITION" ]; then
        mkdir -p "$MOUNT_DIR/boot/efi"
        mount "$BOOT_PARTITION" "$MOUNT_DIR/boot/efi"
    fi
    for dir in dev proc sys; do mount --bind "/$dir" "$MOUNT_DIR/$dir"; done
}
# -----------------------------------------------------------------------------------

# Core GRUB Repair Logic (Inside Chroot)
repair_grub_bootloader() {
    echo "[STEP 1/1] Entering chroot to repair GRUB..."

    chroot "$MOUNT_DIR" /bin/bash <<EOF
        echo "[CHROOT] Running GRUB installation and configuration."

        # --- Detect NixOS and use its dedicated rebuild tool ---
        if command -v nixos-rebuild >/dev/null 2>&1; then
             echo "[CHROOT NIXOS] Detected NixOS. Running system rebuild to fix GRUB."
             nixos-rebuild switch
             exit 0 # Exit chroot block after NixOS rebuild
        fi

        # --- Universal GRUB Repair for other Distros ---
        echo "[CHROOT GRUB] 1. Running grub-install on $DISK_DEVICE (MBR/GPT/UEFI)..."
        
        # Alpine/Gentoo/Arch/Debian/Fedora/OpenSUSE
        grub-install $DISK_DEVICE

        # Regenerate the configuration file
        echo "[CHROOT GRUB] 2. Generating new grub.cfg..."
        # update-grub is a Debian/Ubuntu alias for grub-mkconfig
        update-grub || grub-mkconfig -o /boot/grub/grub.cfg

        echo "[CHROOT] GRUB repair finished."
EOF
}

# Execution
find_and_mount_system # Replace with robust function
repair_grub_bootloader

echo "========================================================================="
echo "[SUCCESS POTENTIAL] GRUB repair complete. Reboot and check."
echo "========================================================================="