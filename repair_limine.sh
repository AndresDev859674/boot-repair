#!/bin/bash
# Script: repair_limine.sh
# Purpose: Repair Limine bootloader installation and configuration.

set -e
trap 'echo -e "\n[FATAL ERROR] Script failed at line $LINENO. Review log: $(pwd)/limine_repair.log"; cleanup; exit 1' ERR
trap cleanup EXIT INT
LOG_FILE="$(pwd)/limine_repair.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================================================="
echo "[INFO] Starting Limine Repair Script. (Log: $LOG_FILE)"
echo "========================================================================="

# Variables
MOUNT_DIR="/mnt/limine_target"
ROOT_PARTITION=""
BOOT_PARTITION="" # EFI partition for UEFI systems
DISK_DEVICE=""

# Functions (Cleanup, find_partitions, mount_and_chroot are assumed to be implemented)

# --- Simplified Partition/Mounting Setup ---
find_and_mount_system() {
    echo "[INFO] Running simplified partition setup."
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
# -------------------------------------------------------------------------

# Core Limine Repair Logic (Inside Chroot)
repair_limine_bootloader() {
    echo "[STEP 1/1] Entering chroot to repair Limine..."

    chroot "$MOUNT_DIR" /bin/bash <<EOF
        echo "[CHROOT] Running Limine installation and configuration."

        # The Limine installation utility is 'limine-install'
        # It handles both BIOS/MBR and UEFI setups.
        if command -v limine-install >/dev/null 2>&1; then
            echo "[CHROOT LIMINE] 1. Running limine-install on $DISK_DEVICE..."
            
            # UEFI mode requires passing the ESP directory
            if [ -d "/boot/efi" ]; then
                limine-install --uefi /boot/efi
            fi
            
            # BIOS/MBR mode
            limine-install $DISK_DEVICE
        else
            echo "[CHROOT LIMINE ERROR] 'limine-install' not found. Please ensure the 'limine' package is installed."
        fi

        echo "[CHROOT LIMINE] 2. Configuration is typically static (/boot/limine.cfg). Assuming it is correct."

        echo "[CHROOT] Limine repair finished."
EOF
}

# Execution
find_and_mount_system # Replace with robust function
repair_limine_bootloader

echo "========================================================================="
echo "[SUCCESS POTENTIAL] Limine repair complete. Reboot and check."
echo "========================================================================="