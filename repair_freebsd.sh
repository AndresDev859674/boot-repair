#!/bin/sh

#================================================
# Advanced Configuration and Error Handling (FreeBSD Shell)
#================================================
# Use 'set -e' for instant exit on error
set -e
# Trap function for cleanup and error reporting
trap 'echo -e "\n[FATAL ERROR] Script failed at line $LINENO. Review log: $(pwd)/boot_repair_freebsd.log"; cleanup; exit 1' ERR
trap cleanup EXIT INT

# Log all output (stdout and stderr) to a file and the console (requires tee)
LOG_FILE="$(pwd)/boot_repair_freebsd.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================================================="
echo "[INFO] Starting Advanced FreeBSD Boot Repair Script. (Log: $LOG_FILE)"
echo "========================================================================="

# --- Initial Confirmation Check ---
read -r -p "WARNING: This script will modify your installed FreeBSD system. Do you want to proceed? (y/N): " initial_confirm
if [ "$initial_confirm" != "y" ] && [ "$initial_confirm" != "Y" ]; then
    echo "[INFO] User canceled the operation. Exiting."
    exit 0
fi

# Temporary mount point
MOUNT_DIR="/mnt/fbsd_target"
# Variables to be set by user/detection
ROOT_PARTITION=""
DISK_DEVICE=""

#================================================
# Core Functions
#================================================

# Clean up mounts and directories on exit/error
cleanup() {
    echo -e "\n[INFO] Starting cleanup process..."
    # Attempt to unmount in reverse order
    # Note: FreeBSD typically uses a single partition for / (UFS) or ZFS datasets.
    
    # Try unmounting the root partition
    if mount | grep -q "$MOUNT_DIR"; then
        echo "[INFO] Unmounting $MOUNT_DIR..."
        umount -f "$MOUNT_DIR" 2>/dev/null || umount -l "$MOUNT_DIR" || true
    fi
    
    # Remove mount directory if empty
    if [ -d "$MOUNT_DIR" ] && [ ! "$(ls -A $MOUNT_DIR)" ]; then
        rmdir "$MOUNT_DIR"
    fi
    echo "[INFO] Cleanup complete."
}

# 1. User Input and Partition Discovery
find_partitions() {
    echo "[STEP 1/5] Identifying and selecting partitions..."
    echo "[INFO] Listing disks (gpart show):"
    gpart show || ls /dev/*da*

    read -r -p "Enter the **ROOT PARTITION** of your FreeBSD system (e.g., /dev/ada0p2 for UFS, or a ZFS pool member): " ROOT_PARTITION
    if [ ! -e "$ROOT_PARTITION" ]; then echo "[FATAL ERROR] Root partition '$ROOT_PARTITION' does not exist. Aborting."; exit 1; fi
    
    read -r -p "Enter the **MAIN DISK DEVICE** (e.g., /dev/ada0) where the boot code will be installed: " DISK_DEVICE
    if [ ! -e "$DISK_DEVICE" ]; then echo "[FATAL ERROR] Disk device '$DISK_DEVICE' does not exist. Aborting."; exit 1; fi

    echo "[INFO] Root: $ROOT_PARTITION, Disk: $DISK_DEVICE"
}

# 2. Mounting and Chroot Preparation (Handle UFS and ZFS)
mount_and_chroot() {
    echo "[STEP 2/5] Mounting partitions and preparing for chroot..."
    mkdir -p "$MOUNT_DIR"
    
    # Check if the root partition is part of a ZFS pool
    if zpool import -n | grep -q "$ROOT_PARTITION" 2>/dev/null; then
        # ZFS detection: Import and mount the pool
        ZPOOL_NAME=$(zpool import -n | grep "$ROOT_PARTITION" | awk '{print $1}' | head -n 1)
        if [ -z "$ZPOOL_NAME" ]; then
             echo "[FATAL ERROR] Could not determine ZFS pool name. Aborting."
             exit 1
        fi
        echo "[INFO] Detected ZFS pool: $ZPOOL_NAME. Importing and mounting."
        zpool import -f -R "$MOUNT_DIR" "$ZPOOL_NAME"
    else
        # UFS detection: Simple mount
        echo "[INFO] Mounting UFS Root: $ROOT_PARTITION to $MOUNT_DIR."
        mount "$ROOT_PARTITION" "$MOUNT_DIR"
    fi
    
    # Check if mounting was successful
    if ! mount | grep -q "$MOUNT_DIR"; then
        echo "[FATAL ERROR] Failed to mount the root filesystem. Aborting."
        exit 1
    fi

    # Bind essential system directories for chroot (FreeBSD specifics)
    echo "[INFO] Binding /dev, /proc, /sys (if available) for chroot."
    # FreeBSD's chroot needs /dev, and /proc/sys are often not bind-mounted
    mount -t devfs devfs "$MOUNT_DIR/dev" || true
}

# 3. Bootloader Repair (Inside Chroot)
repair_bootloader() {
    echo "[STEP 3/5] Entering chroot to repair the bootloader..."

    # Use chroot to execute commands in the installed system
    chroot "$MOUNT_DIR" /bin/sh <<EOF
        echo "[CHROOT] Entered FreeBSD system environment. Running bootloader repairs."
        
        # --- A. Reinstall the boot code to the disk ---
        # Install the primary boot code to the GPT partition scheme (GPT/UEFI)
        echo "[CHROOT] 1. Installing GPT boot code..."
        gpart bootcode -b /boot/pmbr -p /boot/gptboot -i 1 $DISK_DEVICE
        
        # Check for MBR/Legacy boot partition
        if gpart show $DISK_DEVICE | grep -q "freebsd-boot"; then
            BOOT_PARTITION_INDEX=\$(gpart show -l $DISK_DEVICE | grep "freebsd-boot" | awk '{print \$1}' | head -n 1)
            echo "[CHROOT] 2. Reinstalling secondary loader to the boot partition (index $BOOT_PARTITION_INDEX)..."
            gpart bootcode -b /boot/boot $DISK_DEVICE
        fi
        
        # --- B. Reinstalling the Kernel and Configuration ---
        echo "[CHROOT] 3. Verifying /boot/loader.conf..."
        # If the system uses ZFS, ensure the correct ZFS path is in loader.conf
        if [ -n "$ZPOOL_NAME" ]; then
             echo "zfs_load=\"YES\"" >> /boot/loader.conf
        fi
        
        echo "[CHROOT] Bootloader repair finished."
EOF
}

# 4. Filesystem Check (outside chroot, user confirmation)
filesystem_check_confirmation() {
    echo -e "\n[STEP 4/5] Filesystem Check Confirmation."
    read -r -p "Would you like to run a filesystem check (fsck) on $ROOT_PARTITION to repair disk errors? (y/N): " fsck_confirm
    if [ "$fsck_confirm" = "y" ] || [ "$fsck_confirm" = "Y" ]; then
        echo "[INFO] Running fsck on $ROOT_PARTITION. This may take some time."
        
        # Unmount before running fsck
        if mount | grep -q "$MOUNT_DIR"; then
             umount "$MOUNT_DIR" || umount -f "$MOUNT_DIR"
             echo "[INFO] Partition unmounted. Running fsck..."
             fsck -y "$ROOT_PARTITION" # -y is for automatic repair
             
             # Remount after check, if successful
             if [ $? -eq 0 ]; then
                 echo "[INFO] fsck complete. Remounting $ROOT_PARTITION."
                 mount "$ROOT_PARTITION" "$MOUNT_DIR"
             else
                 echo "[ERROR] fsck reported errors that may require manual intervention. Aborting final steps."
                 exit 1
             fi
        fi
    else
        echo "[INFO] Filesystem check skipped."
    fi
}


#================================================
# Execution
#================================================
if [ "$(id -u)" != "0" ]; then
   echo "[FATAL ERROR] This script must be run as root. Aborting." 
   exit 1
fi

find_partitions
mount_and_chroot
repair_bootloader
filesystem_check_confirmation

echo "========================================================================="
echo "[SUCCESS POTENTIAL] FreeBSD boot repair process completed."
echo "NEXT STEPS:"
echo "1. Run 'reboot' and remove the Live USB/CD."
echo "2. If the system fails to boot, verify your ZFS settings in /boot/loader.conf."
echo "========================================================================="
# Cleanup runs automatically due to 'trap cleanup EXIT'