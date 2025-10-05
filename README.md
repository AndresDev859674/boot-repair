```
,--.                   ,--.                                      ,--.       
|  |-.  ,---.  ,---. ,-'  '-.,-----.,--.--. ,---.  ,---.  ,--,--.`--',--.--.
| .-. '| .-. || .-. |'-.  .-''-----'|  .--'| .-. :| .-. |' ,-.  |,--.|  .--'
| `-' |' '-' '' '-' '  |  |         |  |   \   --.| '-' '\ '-'  ||  ||  |   
 `---'  `---'  `---'   `--'         `--'    `----'|  |-'  `--`--'`--'`--'   
```
also known ***boot-repair-andres***

`0.1.2`

- A simple script that which gives you options to repair your boot like ***Screen*** or ***GRUB*** to restore your system’s bootloader.  
Perfect for use from a **live environment** when your motherboard fails to detect the bootloader.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Language-Shell-green)](https://opensource.org/licenses/MIT)
![Bash Script](https://img.shields.io/badge/bash_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

> [!NOTE]
> This is a new version of Auto-GRUB-Repair-Script with aliases and more
>

***This Script is most Perfect in Arch Linux***

---

## Reliability and Project Scope

The current version of this tool is designed to address specific boot issues, primarily focusing on robust and reliable solutions within those defined boundaries.

Our core reliability currently lies in:

* **GRUB Repair:** Providing effective and tested solutions for fixing GRUB bootloader issues across a wide range of supported distributions.
* **System Diagnostics:** Offering utilities to diagnose screen/display issues and perform essential technical checks on the boot configuration.

**Our Current Scope:** Our primary path involves interacting with **bootloaders** (currently GRUB-focused) and performing necessary **technical configurations** to restore system functionality. While our focus is narrow now, we aim for maximum dependability within that scope.

***I'm very obsessed with bootloaders lol***

## Features, ***more coming soon...***
- **Multi‑distro support** with automatic detection
- **UEFI or BIOS** boot mode selection
- **Interactive safety prompts** before making changes
- **Motherboard/system info** display
- **Execution time summary**
- **ASCII art + color‑coded output** for style
- **Reboot option** at the end
- **Repair Monitor**

## 🖥 Supported Distributions

### Base Distributions

| Distribution | UEFI Support | BIOS Support | Status |
|:-------------|:------------:|:------------:|:------:|
| <details><summary>![Arch](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff&style=for-the-badge)</summary><br>**Notes:** Standard Arch installation methods work perfectly. Uses GRUB by default. <br> **Known Issues:** None confirmed.</details> | ✅ | ✅ | ✅ |
| <details><summary>![Debian](https://img.shields.io/badge/Debian-D70A53?style=for-the-badge&logo=debian&logoColor=white)</summary><br>**Notes:** Fully compatible with official GRUB package. Tested on Stable and Testing branches.</details> | ✅ | ✅ | ✅ |
| <details><summary>![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)</summary><br>**Notes:** Full support. If issues arise, use the included `boot-repair` tool.</details> | ✅ | ✅ | ✅ |
| ![Fedora](https://img.shields.io/badge/Fedora-294172?style=for-the-badge&logo=fedora&logoColor=white) | ✅ | ✅ | ✅ |
| ![openSUSE](https://img.shields.io/badge/openSUSE-%2364B345?style=for-the-badge&logo=openSUSE&logoColor=white) | ✅ | ✅ | ❓ |
| ![NixOS](https://img.shields.io/badge/NIXOS-5277C3.svg?style=for-the-badge&logo=NixOS&logoColor=white) | ✅ | ✅ | ❓ |
| ![Alpine Linux](https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white) | ✅ | ✅ | ❓ (Upcoming) |
| ![Gentoo](https://img.shields.io/badge/Gentoo-9B54FF?style=for-the-badge&logo=gentoo&logoColor=white) | ✅ | ✅ | ❌ |
| ![FreeBSD](https://img.shields.io/badge/FreeBSD-CF2122?style=for-the-badge&logo=freebsd&logoColor=white) | ❓ | ❓ | ❓ (Upcoming) |

---

### Derivative Distributions

| Distribution | Base | UEFI Support | BIOS Support | Status |
|:-------------|:------|:------------:|:------------:|:------:|
| <details><summary>![Linux Mint](https://img.shields.io/badge/Linux%20Mint-87CF3E?style=for-the-badge&logo=Linux%20Mint&logoColor=white)</summary><br>**Notes:** Full support confirmed. Based on Ubuntu/Debian, using standard GRUB configuration.</details> | Ubuntu (Debian) | ✅ | ✅ | ✅ |
| <details><summary>![MX Linux](https://img.shields.io/badge/-MX%20Linux-%23000000?style=for-the-badge&logo=MXlinux&logoColor=white)</summary><br>**Notes:** Fully supported due to Debian/antiX base. No extra steps expected.</details> | Debian/antiX | ✅ | ✅ | ✅ |
| <details><summary>![Pop!\_OS](https://img.shields.io/badge/Pop!_OS-48B9C7?style=for-the-badge&logo=pop-os&logoColor=white)</summary><br>**Notes:** Uses Systemd-boot by default, not GRUB. Our fix applies to GRUB-only systems. Manual intervention may be needed to switch to GRUB.</details> | Ubuntu (Debian) | ✅ | ✅ | ✅ |
| ![AnduinOS](https://img.shields.io/badge/AnduinOS-231F20?style=for-the-badge) | Debian/Ubuntu | ✅ | ✅ | ✅ |
| <details><summary>![CachyOS](https://img.shields.io/badge/CachyOS-2396B2?style=for-the-badge&logo=arch-linux&logoColor=white)</summary><br>**Notes:** Arch-based, full GRUB support confirmed.</details> | Arch | ✅ | ✅ | ✅ |
| ![EndeavourOS](https://img.shields.io/badge/EndeavourOS-2D1935?style=for-the-badge&logo=endeavouros&logoColor=white) | Arch | ✅ | ✅ | ✅ |
| <details><summary>![Manjaro](https://img.shields.io/badge/Manjaro-35BF5C?style=for-the-badge&logo=Manjaro&logoColor=white)</summary><br>**Notes:** Known to use a customized GRUB. Compatibility highly likely, but confirmation pending.</details> | Arch | ✅ | ✅ | ❓ |
| ![Kali](https://img.shields.io/badge/Kali-268BEE?style=for-the-badge&logo=kalilinux&logoColor=white) | Debian | ✅ | ✅ | ❓ |
| ![SparkyLinux](https://img.shields.io/badge/SparkyLinux-231F20?style=for-the-badge&logo=debian&logoColor=red) | Debian | ✅ | ✅ | ❓ |
| ![Rocky Linux](https://img.shields.io/badge/-Rocky%20Linux-%2310B981?style=for-the-badge&logo=rockylinux&logoColor=white) | RHEL (Fedora) | ✅ | ✅ | ✅ |
| ![Zorin OS](https://img.shields.io/badge/-Zorin%20OS-%2310AAEB?style=for-the-badge&logo=zorin&logoColor=white) | Ubuntu (Debian) | ✅ | ✅ | ✅ |
| <details><summary>![Elementary OS](https://img.shields.io/badge/-elementary%20OS-black?style=for-the-badge&logo=elementary&logoColor=white)</summary><br>**Notes:** Uses Systemd-boot by default. Full support requires switching to GRUB.</details> | Ubuntu (Debian) | ✅ | ✅ | ❓ |
| ![Raspberry Pi OS](https://img.shields.io/badge/-Raspberry_Pi-C51A4A?style=for-the-badge&logo=Raspberry-Pi) | Debian | ✅ | ✅ | ❓ |
| ![FydeOS](https://img.shields.io/badge/FydeOS-2D3D58?style=for-the-badge) | ChromeOS/Gentoo | ❓ | ❓ | ❌ |
| ![ChromeOS](https://img.shields.io/badge/Chrome_OS-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white) | Gentoo | ❓ | ❓ | ❌ |

---

### Legend

| Icon | Meaning |
|:----:|:-------------------|
| **✅** | **Confirmed Working:** Tested and fully supported. |
| **❓** | **Should Work / Pending Confirmation:** Expected to work (often based on its parent distribution), but testing is pending or needs confirmation. |
| **❌** | **Not Supported:** Confirmed not to work or not supported by the project. |
---

# 🎯 Project Goals & Roadmap

Our primary objective is to expand compatibility beyond current limits. We are actively working on the following major goals:

* **Operating System Expansion:** Implement full support for **FreeBSD** and **Alpine Linux**.
* **Bootloader Diversity:** Integrate support for alternative bootloaders including **Systemd-boot**, **rEFInd**, and **Limine**.
  
Linux is a long world to explore, we are looking for what we can to fix common problems.

---
## 📦 Prerequisites

To ensure a smooth process, you must start from a live environment and have **Git** installed.

* A **Live USB** or live environment of any [Supported Distribution](#-supported-distributions).
* **Internet access** is required for cloning the repository and potentially installing necessary packages.
* **Git** must be installed. You can check the installation with `git --version`.

### Installing Git

If Git is not installed on your live environment, use the corresponding command for your base distribution:

```bash
# Debian, Ubuntu, Mint, Kali, Pop!_OS, etc.
sudo apt update && sudo apt install git

# Fedora, Rocky Linux, etc.
sudo dnf install git

# Arch, Manjaro, CachyOS, EndeavourOS, etc.
sudo pacman -S git
```
---

## Installing form GIT (***For all Distros! + more time...***)
installing From GIT is more Accessible!


1. **Clone the repository**
    ```bash
    git clone https://github.com/AndresDev859674/boot-repair.git
    ```

2. **Navigate into the project folder**
    ```bash
    cd boot-repair
    ```

3. **Make Executable The Script**
    ```bash
    chmod +x boot-repair.sh
    ```

4. **Run the script**
    ```bash
    sudo ./boot-repair.sh
    ```
    Put your Password

---

![alt text](https://raw.githubusercontent.com/AndresDev859674/boot-repair/refs/heads/main/Images/boot-repair-main-menu.png)

**Follow the on-screen instructions**  
   The script will:
   - Select options
   - Make options and more

### Rolling-release
For Rolling-releases please go to The Boot-repair directory and

1. **Make Executable The Script**
    ```bash
    chmod +x *.sh
    ```
2. **Run the script**
    ```bash
    sudo ./rolling-release.sh
    ```
    Put your Password
---

## Installing in AUR (For Arch Users)

1. **Installing form AUR**
   Just install from AUR using yay!
    ```bash
    yay -S boot-repair-andres
    ```

4. **Run the script**
    ```bash
    sudo boot-repair
    ```
    Put your Password

4. **Follow the on-screen instructions**  
   The script will:
   - Select options
   - Make options and more

For Arch Users, This is the easy Method for you!

---

## ⚠️ Notes
- Run this script **only** from a live environment — not from your main OS.  
- Make sure you have **internet access** during the process (some distros require it for package installation).  

---

## installing alias (For Git versions)
- Open **boot-repair** and select options and installed alias in Option *3*
- and the process ends

##### Using Alias with -string
- Quick flags: `-grub` `-monitor` `-initramfs` `-kernel` `-diag` `-update` `-bootcfg` `-auto`
- These are to go faster without selections
  
---

## ⏱️ Older Versions
If you want to go back to other versions (Some are stable) With this you can!

### Older Versions

| Version                 | ID           | Day          |
|-------------------------|--------------|--------------|
| 0.1.1 (not working)     | ./0.1.1.sh   | ❌           |
| 0.1.0                   | ./.0.1.0.sh  | ❌           |

### Installing
Let's to Use Older Versions

1. **Clone the repository**
    ```bash
    git clone https://github.com/AndresDev859674/boot-repair.git
    ```

2. **Navigate into the project folder**
    ```bash
    cd boot-repair
    ```

3. **Make Executable The Script**
    ```bash
    chmod +x *.sh
    ```
4. **Search a Version**
    ```bash
    ls
    ```
    Search a version, For example 0.1.0.sh

5. **Run the script**
    ```bash
    sudo ./*version here*.sh
    ```
    Put your Password

---

![alt text](https://raw.githubusercontent.com/AndresDev859674/boot-repair/refs/heads/main/Images/boot-repair-main-menu.png)

**Follow the on-screen instructions**  
   The script will:
   - Select options
   - Make options and more

---
## 🛠 Repair GNU/GRUB and working

> [!WARNING]
> This is not a definitive option, it is in process and being investigated. We know it is a bad connection with the motherboard. Be careful.
>
- Open **boot-repair** and select
  `1) Repair Grub`

**Follow the on-screen instructions**  
   The script will:
   - Select options
   - Make options and more

---
[![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/AndresDev859674/boot-repair)
[![GitLab](https://img.shields.io/badge/gitlab-%23181717.svg?style=for-the-badge&logo=gitlab&logoColor=white)](https://gitlab.com/AndresDev859674/boot-repair)
![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white)
