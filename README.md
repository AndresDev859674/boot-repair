```
,--.                   ,--.                                      ,--.       
|  |-.  ,---.  ,---. ,-'  '-.,-----.,--.--. ,---.  ,---.  ,--,--.`--',--.--.
| .-. '| .-. || .-. |'-.  .-''-----'|  .--'| .-. :| .-. |' ,-.  |,--.|  .--'
| `-' |' '-' '' '-' '  |  |         |  |   \   --.| '-' '\ '-'  ||  ||  |   
 `---'  `---'  `---'   `--'         `--'    `----'|  |-'  `--`--'`--'`--'   
```

`0.1.1`

- A simple script that which gives you options to repair your boot like ***Screen*** or ***GRUB*** to restore your system’s bootloader.  
Perfect for use from a **live environment** when your motherboard fails to detect the bootloader.

> [!NOTE]
> This is a new version of Auto-GRUB-Repair-Script with aliases and more
>

---

## Features, ***more coming soon...***
- **Multi‑distro support** with automatic detection
- **UEFI or BIOS** boot mode selection
- **Interactive safety prompts** before making changes
- **Motherboard/system info** display
- **Execution time summary**
- **ASCII art + color‑coded output** for style
- **Reboot option** at the end
- **Repair Monitor**
- **and Languages**
  
## 🖥 Supported Distributions

| Distribution  | UEFI Support | BIOS Support |
|---------------|--------------|--------------|
| Arch Linux    | ✅           | ✅           |
| EndeavourOS   | ✅           | ✅           |
| CachyOS       | ✅           | ✅           |
| Debian        | ✅           | ✅           |
| Ubuntu        | ✅           | ✅           |
| Fedora        | ✅           | ✅           |
| openSUSE      | ✅           | ✅           |
| NixOS         | ✅           | ✅           |


---

## 📦 Prerequisites
- A **live USB** or live environment of any supported distro  
- **Git** installed (check with `git --version`)  
  - If not installed, install it using your package manager:  
    ```bash
    # Debian/Ubuntu
    sudo apt install git
    
    # Fedora
    sudo dnf install git
    
    # Arch/EndeavourOS
    sudo pacman -S git
    ```

---

## Installing form GIT (***For all Distros! + more time...***)

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

4. **Follow the on-screen instructions**  
   The script will:
   - Select options
   - Make options and more

---


## Installing in AUR (For Arch Users + BUT OUTDATED)

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

## Repair GNU/GRUB and working
> [!WARNING]
> This is not a definitive option, it is in process and being investigated. We know it is a bad connection with the motherboard. Be careful.
> 
- Open **boot-repair** and select
 `1) Repair Grub`

**Follow the on-screen instructions**  
   The script will:
   - Detect and mount your system partitions  
   - Reinstall GRUB automatically  
   - Restore your bootloader so you can boot normally again  
---
