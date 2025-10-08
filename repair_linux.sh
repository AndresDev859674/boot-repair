#!/bin/bash

#================================================
# Advanced Configuration and Error Handling
#================================================
set -e
trap 'echo -e "\n[FATAL ERROR] Script failed at line $LINENO. Review log: $(pwd)/boot_repair.log"; cleanup; exit 1' ERR
trap cleanup EXIT INT

# Log all output to a file and the console
LOG_FILE="$(pwd)/boot_repair.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================================================="
echo "[INFO] Starting Advanced Universal Boot Repair Script. (Log: $LOG_FILE)"
echo "========================================================================="

# --- Initial Confirmation Check ---
read -r -p "WARNING: This script will modify your installed Linux system. Do you want to proceed? (y/N): " initial_confirm
if [[ ! "$initial_confirm" =~ ^[Yy]$ ]]; then
    echo "[INFO] User canceled the operation. Exiting."
    exit 0
fi

# Temporary mount point
MOUNT_DIR="/mnt/repair_target"
# Variables to be set by user/detection
ROOT_PARTITION=""
BOOT_PARTITION=""
DISK_DEVICE=""
BOOTLOADER_TYPE="GRUB" # Default assumption

#================================================
# Core Functions
#================================================

# Clean up mounts and directories on exit/error
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

# 1. User Input and Partition Discovery
find_partitions() {
    echo "[STEP 1/6] Identifying and selecting partitions..."
    echo "[INFO] Listing disks (fdisk -l):"
    fdisk -l || lsblk
    
    read -r -p "Enter the **ROOT PARTITION** (e.g., /dev/sda2): " ROOT_PARTITION
    if [ ! -e "$ROOT_PARTITION" ]; then echo "[FATAL ERROR] Root partition '$ROOT_PARTITION' does not exist. Aborting."; exit 1; fi
    
    read -r -p "Enter the **EFI PARTITION** (e.g., /dev/sda1) if using UEFI, or leave blank: " BOOT_PARTITION
    
    read -r -p "Enter the **MAIN DISK DEVICE** (e.g., /dev/sda) where the bootloader will be installed: " DISK_DEVICE
    if [ ! -b "$DISK_DEVICE" ]; then echo "[FATAL ERROR] Disk device '$DISK_DEVICE' is not a block device. Aborting."; exit 1; fi

    read -r -p "Enter the **BOOTLOADER TYPE** (GRUB, SYSTEMD, or NIX, default: GRUB): " BOOTLOADER_TYPE_INPUT
    if [ -n "$BOOTLOADER_TYPE_INPUT" ]; then
        BOOTLOADER_TYPE=$(echo "$BOOTLOADER_TYPE_INPUT" | tr '[:lower:]' '[:upper:]')
    fi

    echo "[INFO] Root: $ROOT_PARTITION, EFI: $BOOT_PARTITION, Disk: $DISK_DEVICE, Bootloader: $BOOTLOADER_TYPE"
}

# 2. Mounting and Chroot Preparation
mount_and_chroot() {
    echo "[STEP 2/6] Mounting partitions and preparing for chroot..."
    mkdir -p "$MOUNT_DIR"
    
    echo "[INFO] Mounting Root: $ROOT_PARTITION to $MOUNT_DIR."
    mount "$ROOT_PARTITION" "$MOUNT_DIR"
    
    if [ -n "$BOOT_PARTITION" ] && [ -e "$BOOT_PARTITION" ]; then
        mkdir -p "$MOUNT_DIR/boot/efi"
        echo "[INFO] Mounting EFI: $BOOT_PARTITION to $MOUNT_DIR/boot/efi."
        mount "$BOOT_PARTITION" "$MOUNT_DIR/boot/efi"
    fi

    echo "[INFO] Binding /dev, /proc, /sys."
    for dir in dev proc sys; do
        mount --bind "/$dir" "$MOUNT_DIR/$dir"
    done
}

# 3. Graphics Reset Confirmation (Outside Chroot)
graphics_reset_confirmation() {
    echo -e "\n[STEP 3/6] Graphics Reset Confirmation."
    read -r -p "If your system boots to a BLACK SCREEN or fails to load the desktop (Xorg/Wayland), would you like to RESET the graphics configuration (recommended)? (y/N): " graphics_confirm
    if [[ "$graphics_confirm" =~ ^[Yy]$ ]]; then
        touch "$MOUNT_DIR/tmp/RESET_GRAPHICS_CONFIRM"
        echo "[INFO] Flag set to execute graphics reset inside chroot."
    else
        echo "[INFO] Graphics reset skipped."
    fi
}

# 4. Bootloader and Kernel Repair (Inside Chroot)
repair_boot_and_kernel() {
    echo "[STEP 4/6] Entering chroot to repair the bootloader and kernel configuration..."

    chroot "$MOUNT_DIR" /bin/bash <<EOF
        echo "[CHROOT] Entered system environment. Running bootloader and kernel repairs."
        
        # --- A. Detect Package Manager and Distro ---
        PKG_MANAGER="none"
        if command -v apt >/dev/null 2>&1; then PKG_MANAGER="apt"; fi
        if command -v pacman >/dev/null 2>&1; then PKG_MANAGER="pacman"; fi
        if command -v dnf >/dev/null 2>&1; then PKG_MANAGER="dnf"; fi
        if command -v zypper >/dev/null 2>&1; then PKG_MANAGER="zypper"; fi # OpenSUSE
        if command -v apk >/dev/null 2>&1; then PKG_MANAGER="apk"; fi       # Alpine
        if command -v nixos-rebuild >/dev/null 2>&1; then PKG_MANAGER="nixos"; fi # NixOS

        echo "[CHROOT INFO] Detected Package Manager/Distro: \$PKG_MANAGER"

        # --- B. Bootloader Specific Repair Logic ---

        if [ "$BOOTLOADER_TYPE" == "GRUB" ]; then
            echo "[CHROOT GRUB] Starting GRUB repair."
            grub-install $DISK_DEVICE
            update-grub || grub-mkconfig -o /boot/grub/grub.cfg
        
        elif [ "$BOOTLOADER_TYPE" == "SYSTEMD" ]; then
            echo "[CHROOT SYSTEMD] Running bootctl install/update..."
            bootctl install || bootctl update

        elif [ "$BOOTLOADER_TYPE" == "NIX" ]; then
            echo "[CHROOT NIXOS] Running nixos-rebuild to apply the system configuration (includes bootloader)..."
            if command -v nixos-rebuild >/dev/null 2>&1; then
                nixos-rebuild switch
            else
                echo "[CHROOT NIXOS ERROR] 'nixos-rebuild' not found. Ensure configuration is correct."
            fi

        fi
        
        # --- C. Kernel and Initramfs Regeneration (Critical for all) ---
        echo "[CHROOT KERNEL] Regenerating Initramfs images (Crucial for hardware/SSD changes)..."
        
        if [ "\$PKG_MANAGER" == "zypper" ]; then
            # OpenSUSE uses grub2-mkconfig and mkinitrd/dracut
            mkinitrd || dracut -f
        elif [ "\$PKG_MANAGER" == "apk" ]; then
            # Alpine Linux
            LATEST_KERNEL=\$(ls /lib/modules/ | tail -n 1)
            mkinitfs \$LATEST_KERNEL
            lbu package # Alpine-specific command to commit changes if using a persistent setup
        elif [ "\$PKG_MANAGER" == "none" ] && [ -f "/etc/gentoo-release" ]; then
            # Gentoo (requires manual tools if system is not set up fully)
            echo "[CHROOT GENTOO] Re-generating kernel symlinks and initramfs (assuming genkernel/dracut is installed)."
            if command -v genkernel >/dev/null 2>&1; then
                genkernel --install initramfs
            elif command -v dracut >/dev/null 2>&1; then
                dracut -f
            fi
            
        elif command -v update-initramfs >/dev/null 2>&1; then
            update-initramfs -u -k all
        elif command -v dracut >/dev/null 2>&1; then
            LATEST_KERNEL=\$(ls /boot/vmlinuz-* | sed 's|/boot/vmlinuz-||' | sort -V | tail -n 1)
            dracut -f --kver "\$LATEST_KERNEL"
        else
            echo "[CHROOT KERNEL WARNING] Initramfs regeneration tool not found. Skipping."
        fi


        # --- D. Graphics Environment Reset (Xorg/Wayland) ---
        if [ -f "/tmp/RESET_GRAPHICS_CONFIRM" ]; then
            echo "[CHROOT GRAPHICS] Resetting Xorg/Wayland configuration files..."
            
            # Backup and remove generic xorg.conf
            if [ -d "/etc/X11" ]; then
                mv /etc/X11/xorg.conf /etc/X11/xorg.conf.bak.\$(date +%Y%m%d%H%M%S) 2>/dev/null || true
            fi
            
            # Reconfigure for known package managers
            if [ "\$PKG_MANAGER" == "apt" ]; then
                dpkg-reconfigure xserver-xorg || true
            elif [ "\$PKG_MANAGER" == "zypper" ]; then
                echo "[CHROOT GRAPHICS] OpenSUSE: Consider using YaST or re-installing xorg-x11 packages."
            fi
            
            echo "[CHROOT GRAPHICS] Graphics reset complete."
        else
            echo "[CHROOT GRAPHICS INFO] Graphics reset skipped by user request."
        fi

        echo "[CHROOT] Repair steps finished. Exiting chroot."
EOF
}

# 5. Final System Health Check Recommendations
health_check_recommendations() {
    echo -e "\n[STEP 5/6] Final System Health Check Recommendations."
    
    # Recommend filesystem check (can't be done while mounted)
    echo "[RECOMMENDATION] **CRITICAL:** Before rebooting, run a filesystem check (fsck) on the root partition."
    echo "   -> Syntax: fsck -y $ROOT_PARTITION (from the Live USB terminal, *after* exiting this script)."
}

#================================================
# Execution
#================================================
if [ "$(id -u)" != "0" ]; then
   echo "[FATAL ERROR] This script must be run as root (use sudo). Aborting." 
   exit 1
fi

find_partitions
mount_and_chroot
graphics_reset_confirmation
repair_boot_and_kernel
health_check_recommendations

echo "========================================================================="
echo "[SUCCESS POTENTIAL] Universal boot repair process completed."
echo "NEXT STEPS:"
echo "1. Run the recommended 'fsck' command if you suspect disk errors."
echo "2. Run 'reboot' and remove the Live USB/CD."
echo "3. If successful, run a full system update."
echo "========================================================================="