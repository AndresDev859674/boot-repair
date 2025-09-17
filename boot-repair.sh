#!/usr/bin/env bash
#========================================================
#  BootRepair v2.0
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
# Language (ES/EN/DE/PT)
#-----------------------
LANG_CODE="es"
case "${LANG:-es}" in
  es_*|es) LANG_CODE="es" ;;
  en_*|en) LANG_CODE="en" ;;
  de_*|de) LANG_CODE="de" ;;
  pt_*|pt) LANG_CODE="pt" ;;
  *) LANG_CODE="en" ;;
esac

declare -A T
if [[ "$LANG_CODE" == "es" ]]; then
  T[title]="BootRepair"
  T[gather]="Recopilando información del sistema..."
  T[detected_distro]="Distribución detectada"
  T[detected_arch]="Arquitectura detectada"
  T[detected_mode]="Modo de arranque detectado"
  T[secureboot]="Estado de Secure Boot"
  T[secure_on]="ACTIVADO"
  T[secure_off]="DESACTIVADO"
  T[secure_unknown]="No determinado"
  T[menu_title]="Menú principal"
  T[m1]="1) Reparar GRUB"
  T[m2]="2) Reparar configuración de monitores (Wayland/Hyprland/Xorg)"
  T[m3]="3) Regenerar initramfs"
  T[m4]="4) Reinstalar kernel"
  T[m5]="5) Actualizar sistema operativo"
  T[m6]="6) Libertad de arranque (timeout, default, EFI, os-prober)"
  T[m7]="7) Diagnóstico rápido"
  T[m8]="8) Ajustes (idioma, modo experto, instalar alias)"
  T[m9]="10) Salir"
  T[enter_choice]="Elige una opción"
  T[press_enter]="Pulsa Enter para continuar..."
  T[need_root]="Este script requiere privilegios de administrador (sudo)."
  T[warn_boot]="ADVERTENCIA: Esto modificará tu cargador de arranque."
  T[proceed]="¿Deseas continuar? [y/N]: "
  T[cancelled]="Operación cancelada."
  T[auto_mode]="¿Modo automático? (detectar raíz/EFI) [y/N]: "
  T[select_root]="Elige tu partición raíz"
  T[select_efi]="Elige tu partición EFI (vfat, ~100–500 MB)"
  T[efi_hint]="Sugerencia: selecciona la partición con tipo vfat/FAT32 y etiqueta EFI/ESP."
  T[no_parts]="No se detectaron particiones adecuadas."
  T[invalid_sel]="Selección inválida."
  T[mounting]="Montando y preparando chroot..."
  T[binds]="Realizando bind-mounts..."
  T[repairing_for]="Reparando GRUB para"
  T[done]="Listo."
  T[total_time]="Tiempo total"
  T[reboot_now]="¿Reiniciar ahora? [y/N]: "
  T[rebooting]="Reiniciando..."
  T[reboot_later]="Puedes reiniciar más tarde manualmente."
  T[bios_disk]="Selecciona el disco donde instalar GRUB (BIOS/Legacy)"
  T[disk_from_root]="Detectando disco desde la raíz seleccionada..."
  T[uefi_skip_disk]="En UEFI no es necesario seleccionar disco."
  T[pkg_hint]="Asegúrate de tener instalado grub en el sistema objetivo."
  T[nixos_hint]="En NixOS, los cambios se aplican con nixos-rebuild."
  T[auto_detecting]="Detectando automáticamente particiones..."
  T[auto_fail]="No se pudo detectar automáticamente. Cambiando a selección manual."
  T[selected]="Seleccionado"
  T[boot_name]="¿Nombre para el menú UEFI? (por defecto: Linux) >> "
  T[gpu_note]="Reseteando configuraciones de monitor para Wayland/Hyprland y Xorg."
  T[initramfs_done]="initramfs regenerado (si aplica)."
  T[kernel_note]="Se intentará reinstalar el kernel con el gestor de paquetes."
  T[diag_title]="Diagnóstico de sistema"
  T[settings_title]="Ajustes"
  T[set_lang]="1) Cambiar idioma (ES/EN/DE/PT)"
  T[set_expert]="2) Alternar modo experto"
  T[set_install]="3) Instalar 'bootrepair' en /usr/local/bin (Solo para repositorios GIT)"
  T[back]="5) Volver"
  T[expert_on]="Modo experto ACTIVADO"
  T[expert_off]="Modo experto DESACTIVADO"
  T[installed_alias]="Instalado /usr/local/bin/bootrepair"
  T[already_alias]="Ya existe /usr/local/bin/bootrepair"
  T[bootcfg_title]="Libertad de arranque"
  T[bc1]="1) Cambiar timeout de GRUB"
  T[bc2]="2) Cambiar entrada por defecto de GRUB"
  T[bc3]="3) Habilitar os-prober y regenerar"
  T[bc4]="4) Gestionar entradas EFI (listar/orden/bootnext)"
  T[bc5]="5) Volver"
  T[enter_timeout]="Nuevo timeout (segundos) >> "
  T[enter_default]="Nueva entrada por defecto (por ejemplo, 0 o 'Advanced options>...') >> "
  T[updated]="Actualizado."
  T[efimenu]="EFI: 1) Listar  2) Establecer orden  3) Establecer BootNext  4) Volver"
  T[enter_order]="Introduce orden (p.ej. 0003,0001,0000) >> "
  T[enter_bootnext]="Introduce BootNext (p.ej. 0003) >> "
  T[update_title]="Actualizar sistema operativo"
  T[update_warn]="Esto actualizará paquetes en el sistema objetivo."
  T[updating]="Actualizando..."
  T[set_uninstall]="4) Desinstalar 'bootrepair' de /usr/local/bin"
  T[uninstalled_alias]="'bootrepair' eliminado de /usr/local/bin"
  T[no_alias]="'bootrepair' no está instalado en /usr/local/bin"

elif [[ "$LANG_CODE" == "de" ]]; then
  T[title]="BootRepair"
  T[gather]="Systeminformationen werden gesammelt..."
  T[detected_distro]="Erkannte Distribution"
  T[detected_arch]="Erkannte Architektur"
  T[detected_mode]="Erkannter Bootmodus"
  T[secureboot]="Secure Boot Status"
  T[secure_on]="AKTIVIERT"
  T[set_uninstall]="4) Deinstallieren Sie „bootrepair“ aus /usr/local/bin"
  T[uninstalled_alias]="'Boot-Reparatur‘ aus /usr/local/bin entfernt"
  T[no_alias]="'„bootrepair“ ist nicht in /usr/local/bin installiert"
  T[secure_off]="DEAKTIVIERT"
  T[secure_unknown]="Unbekannt"
  T[menu_title]="Hauptmenü"
  T[m1]="1) GRUB reparieren"
  T[m2]="2) Monitor-/Anzeigeeinstellungen zurücksetzen (Wayland/Hyprland/Xorg)"
  T[m3]="3) initramfs neu erzeugen"
  T[m4]="4) Kernel neu installieren"
  T[m5]="5) Betriebssystem aktualisieren"
  T[m6]="6) Boot-Freiheit (Timeout, Default, EFI, os-prober)"
  T[m7]="7) Schnell-Diagnose"
  T[m8]="8) Einstellungen (Sprache, Expertenmodus, Alias installieren)"
  T[m9]="10) Beenden"
  T[enter_choice]="Option wählen"
  T[press_enter]="Drücke Enter zum Fortfahren..."
  T[need_root]="Dieses Skript erfordert Administratorrechte (sudo)."
  T[warn_boot]="WARNUNG: Dies verändert deinen Bootloader."
  T[proceed]="Fortfahren? [y/N]: "
  T[cancelled]="Vorgang abgebrochen."
  T[auto_mode]="Automatikmodus? (Root/EFI erkennen) [y/N]: "
  T[select_root]="Root-Partition wählen"
  T[select_efi]="EFI-Partition wählen (vfat, ~100–500 MB)"
  T[efi_hint]="Hinweis: wähle vfat/FAT32 mit EFI/ESP Label."
  T[no_parts]="Keine passenden Partitionen gefunden."
  T[invalid_sel]="Ungültige Auswahl."
  T[mounting]="Einbinden und chroot vorbereiten..."
  T[binds]="Bind-Mounts werden durchgeführt..."
  T[repairing_for]="GRUB Reparatur für"
  T[done]="Fertig."
  T[total_time]="Gesamtzeit"
  T[reboot_now]="Jetzt neu starten? [y/N]: "
  T[rebooting]="Neustart..."
  T[reboot_later]="Du kannst später manuell neu starten."
  T[bios_disk]="Festplatte für GRUB-Installation wählen (BIOS/Legacy)"
  T[disk_from_root]="Ermittle Festplatte aus Root-Partition..."
  T[uefi_skip_disk]="Unter UEFI ist keine Plattenauswahl nötig."
  T[pkg_hint]="Stelle sicher, dass grub im Zielsystem installiert ist."
  T[nixos_hint]="Unter NixOS werden Änderungen via nixos-rebuild angewandt."
  T[auto_detecting]="Partitionen werden automatisch erkannt..."
  T[auto_fail]="Automatische Erkennung fehlgeschlagen. Manuelle Auswahl."
  T[selected]="Ausgewählt"
  T[boot_name]="Name für UEFI-Menü? (Standard: Linux) >> "
  T[gpu_note]="Monitor-/Anzeige-Konfigurationen für Wayland/Hyprland und Xorg zurücksetzen."
  T[initramfs_done]="initramfs neu erzeugt (falls zutreffend)."
  T[kernel_note]="Kernel wird über Paketverwaltung neu installiert."
  T[diag_title]="Systemdiagnose"
  T[settings_title]="Einstellungen"
  T[set_lang]="1) Sprache ändern (ES/EN/DE/PT)"
  T[set_expert]="2) Expertenmodus umschalten"
  T[set_install]="3) 'bootrepair' nach /usr/local/bin installieren (Nur für GIT-Repositorys)"
  T[back]="5) Zurück"
  T[expert_on]="Expertenmodus AKTIVIERT"
  T[expert_off]="Expertenmodus DEAKTIVIERT"
  T[installed_alias]="'bootrepair' wurde installiert"
  T[already_alias]="/usr/local/bin/bootrepair existiert bereits"
  T[bootcfg_title]="Boot-Freiheit"
  T[bc1]="1) GRUB Timeout ändern"
  T[bc2]="2) GRUB Standard-Eintrag ändern"
  T[bc3]="3) os-prober aktivieren und neu generieren"
  T[bc4]="4) EFI-Einträge verwalten (Liste/Reihenfolge/BootNext)"
  T[bc5]="5) Zurück"
  T[enter_timeout]="Neuer Timeout (Sekunden) >> "
  T[enter_default]="Neuer Standard-Eintrag (z.B. 0 oder 'Advanced options>...') >> "
  T[updated]="Aktualisiert."
  T[efimenu]="EFI: 1) Liste  2) Reihenfolge setzen  3) BootNext setzen  4) Zurück"
  T[enter_order]="Reihenfolge (z.B. 0003,0001,0000) >> "
  T[enter_bootnext]="BootNext (z.B. 0003) >> "
  T[update_title]="Betriebssystem aktualisieren"
  T[update_warn]="Dies aktualisiert Pakete im Zielsystem."
  T[updating]="Aktualisiere..."
elif [[ "$LANG_CODE" == "pt" ]]; then
  T[title]="BootRepair"
  T[gather]="Coletando informações do sistema..."
  T[detected_distro]="Distribuição detectada"
  T[detected_arch]="Arquitetura detectada"
  T[detected_mode]="Modo de boot detectado"
  T[secureboot]="Status do Secure Boot"
  T[secure_on]="ATIVADO"
  T[secure_off]="DESATIVADO"
  T[set_uninstall]="4) Desinstale 'bootrepair' de /usr/local/bin"
  T[uninstalled_alias]="''reparo de inicialização' removido de /usr/local/bin"
  T[no_alias]="'bootrepair' não está instalado em /usr/local/bin"
  T[secure_unknown]="Desconhecido"
  T[menu_title]="Menu principal"
  T[m1]="1) Reparar GRUB"
  T[m2]="2) Reparar configurações de monitor (Wayland/Hyprland/Xorg)"
  T[m3]="3) Regenerar initramfs"
  T[m4]="4) Reinstalar kernel"
  T[m5]="5) Atualizar sistema"
  T[m6]="6) Liberdade de boot (timeout, default, EFI, os-prober)"
  T[m7]="7) Diagnóstico rápido"
  T[m8]="8) Configurações (idioma, modo avançado, instalar alias)"
  T[m9]="10) Sair"
  T[enter_choice]="Escolha uma opção"
  T[press_enter]="Pressione Enter para continuar..."
  T[need_root]="Este script requer privilégios de administrador (sudo)."
  T[warn_boot]="AVISO: Isto modificará seu bootloader."
  T[proceed]="Deseja continuar? [y/N]: "
  T[cancelled]="Operação cancelada."
  T[auto_mode]="Modo automático? (detectar root/EFI) [y/N]: "
  T[select_root]="Selecione sua partição root"
  T[select_efi]="Selecione sua partição EFI (vfat, ~100–500 MB)"
  T[efi_hint]="Dica: escolha vfat/FAT32 com rótulo EFI/ESP."
  T[no_parts]="Nenhuma partição adequada detectada."
  T[invalid_sel]="Seleção inválida."
  T[mounting]="Montando e preparando chroot..."
  T[binds]="Executando bind-mounts..."
  T[repairing_for]="Reparando GRUB para"
  T[done]="Concluído."
  T[total_time]="Tempo total"
  T[reboot_now]="Reiniciar agora? [y/N]: "
  T[rebooting]="Reiniciando..."
  T[reboot_later]="Você pode reiniciar depois manualmente."
  T[bios_disk]="Selecione o disco para instalar o GRUB (BIOS/Legacy)"
  T[disk_from_root]="Determinando disco a partir do root..."
  T[uefi_skip_disk]="Em UEFI não é necessário selecionar disco."
  T[pkg_hint]="Garanta que o grub esteja instalado no sistema alvo."
  T[nixos_hint]="No NixOS, mudanças via nixos-rebuild."
  T[auto_detecting]="Detectando partições automaticamente..."
  T[auto_fail]="Falha na detecção automática. Mudando para seleção manual."
  T[selected]="Selecionado"
  T[boot_name]="Nome para o menu UEFI? (padrão: Linux) >> "
  T[gpu_note]="Redefinindo configurações de monitor para Wayland/Hyprland e Xorg."
  T[initramfs_done]="initramfs regenerado (quando aplicável)."
  T[kernel_note]="Tentará reinstalar o kernel pelo gerenciador de pacotes."
  T[diag_title]="Diagnóstico do sistema"
  T[settings_title]="Configurações"
  T[set_lang]="1) Trocar idioma (ES/EN/DE/PT)"
  T[set_expert]="2) Alternar modo avançado"
  T[set_install]="3) Instalar 'bootrepair' em /usr/local/bin (Somente para repositórios GIT)"
  T[back]="5) Voltar"
  T[expert_on]="Modo avançado ATIVADO"
  T[expert_off]="Modo avançado DESATIVADO"
  T[installed_alias]="'bootrepair' instalado"
  T[already_alias]="/usr/local/bin/bootrepair já existe"
  T[bootcfg_title]="Liberdade de boot"
  T[bc1]="1) Alterar timeout do GRUB"
  T[bc2]="2) Alterar entrada padrão do GRUB"
  T[bc3]="3) Ativar os-prober e regenerar"
  T[bc4]="4) Gerenciar entradas EFI (listar/ordem/bootnext)"
  T[bc5]="5) Voltar"
  T[enter_timeout]="Novo timeout (segundos) >> "
  T[enter_default]="Nova entrada padrão (ex.: 0 ou 'Advanced options>...') >> "
  T[updated]="Atualizado."
  T[efimenu]="EFI: 1) Listar  2) Definir ordem  3) Definir BootNext  4) Voltar"
  T[enter_order]="Informe a ordem (ex.: 0003,0001,0000) >> "
  T[enter_bootnext]="Informe o BootNext (ex.: 0003) >> "
  T[update_title]="Atualizar sistema"
  T[update_warn]="Isto atualizará pacotes no sistema alvo."
  T[updating]="Atualizando..."
else
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
  T[set_lang]="1) Change language (ES/EN/DE/PT)"
  T[set_expert]="2) Toggle expert mode"
  T[set_install]="3) Install 'bootrepair' to /usr/local/bin (Only for GIT repositories)"
  T[back]="5) Back"
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
  echo -e "${YELLOW}=== ${T[title]} v2.0 ===${RESET}"
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
  if command -v dmidecode &>/dev/null; then
    echo "Motherboard: $(dmidecode -s baseboard-manufacturer 2>/dev/null) $(dmidecode -s baseboard-product-name 2>/dev/null)"
  fi
  DISTRO="unknown"
  if [[ -f /etc/os-release ]]; then . /etc/os-release; DISTRO="$ID"; fi
  echo -e "${GREEN}${T[detected_distro]}:${RESET} $DISTRO"
  if [[ -d /sys/firmware/efi/efivars ]]; then BOOT_MODE="UEFI"; else BOOT_MODE="BIOS"; fi
  echo -e "${GREEN}${T[detected_mode]}:${RESET} $BOOT_MODE"
  echo -e "${GREEN}${T[secureboot]}:${RESET} $(secure_boot_status)"
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
    # Colores
    RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"

    # Detectar distribución
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "${RED}No se pudo detectar la distribución.${RESET}"
        return 1
    fi
    echo -e "${GREEN}Distribución detectada:${RESET} $DISTRO"

    # Seleccionar modo de arranque
    echo -e "${CYAN}Selecciona el modo de arranque:${RESET}"
    echo "1) UEFI (recomendado)"
    echo "2) BIOS (Legacy)"
    read -rp "Opción [1/2]: " BOOT_MODE
    if [ "$BOOT_MODE" != "1" ] && [ "$BOOT_MODE" != "2" ]; then
        echo -e "${RED}Opción inválida. Usando UEFI por defecto.${RESET}"
        BOOT_MODE=1
    fi

    # Confirmar reparación
    echo -e "${YELLOW}ADVERTENCIA:${RESET} Esto modificará el gestor de arranque."
    read -rp "¿Deseas continuar? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operación cancelada.${RESET}"
        return 0
    fi

    # Montar particiones
    read -rp "Introduce tu partición raíz (ej: /dev/sda2): " ROOT_PART
    if [ "$BOOT_MODE" = "1" ]; then
        read -rp "Introduce tu partición EFI (ej: /dev/sda1): " EFI_PART
    fi
    echo -e "${CYAN}Montando particiones...${RESET}"
    sudo mount "$ROOT_PART" /mnt
    if [ "$BOOT_MODE" = "1" ]; then
        sudo mount "$EFI_PART" /mnt/boot/efi
    fi

    # Reparar GRUB según la distro
    case "$DISTRO" in
        arch|endeavouros|cachyos)
            echo -e "${YELLOW}Reparando GRUB en Arch-based...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo pacman -Sy arch-install-scripts
                sudo arch-chroot /mnt /bin/bash -c "
                    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    grub-mkconfig -o /boot/grub/grub.cfg
                "
            else
                sudo pacman -Sy arch-install-scripts
                sudo arch-chroot /mnt /bin/bash -c "
                    grub-install --target=i386-pc /dev/sda &&
                    grub-mkconfig -o /boot/grub/grub.cfg
                "
            fi
            ;;
        debian|ubuntu)
            echo -e "${YELLOW}Reparando GRUB en Debian/Ubuntu...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo chroot /mnt /bin/bash -c "
                    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    update-grub
                "
            else
                sudo chroot /mnt /bin/bash -c "
                    grub-install --target=i386-pc /dev/sda &&
                    update-grub
                "
            fi
            ;;
        fedora)
            echo -e "${YELLOW}Reparando GRUB en Fedora...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo chroot /mnt /bin/bash -c "
                    grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            else
                sudo chroot /mnt /bin/bash -c "
                    grub2-install --target=i386-pc /dev/sda &&
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            fi
            ;;
        opensuse*|suse)
            echo -e "${YELLOW}Reparando GRUB en openSUSE...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo chroot /mnt /bin/bash -c "
                    grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux &&
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            else
                sudo chroot /mnt /bin/bash -c "
                    grub2-install --target=i386-pc /dev/sda &&
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            fi
            ;;
        nixos)
            echo -e "${YELLOW}Reparando GRUB en NixOS...${RESET}"
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
            echo -e "${RED}Distribución no soportada: $DISTRO${RESET}"
            return 1
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
    echo "${T[back]}"
    local c; read -r -p ">> " c </dev/tty
    case "$c" in
      1)
        case "$LANG_CODE" in
          es) LANG=en ;;
          en) LANG=de ;;
          de) LANG=pt ;;
          *) LANG=es ;;
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
      5) break ;;
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
  echo -e "${YELLOW}=== ${T[title]} v2.0 ===${RESET}"
    echo "Quick flags: -grub -monitor -initramfs -kernel -diag -update -bootcfg -auto"
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


#-----------------------
# Menu
#-----------------------
main_menu() {
  while true; do
    ascii_banner
    info_header
    echo -e "${YELLOW}=== ${T[menu_title]} ===${RESET}"
    echo "${T[m1]}"
    echo "${T[m2]}"
    echo "${T[m3]}"
    echo "${T[m4]}"
    echo "${T[m5]}"
    echo "${T[m6]}"
    echo "${T[m7]}"
    echo "${T[m8]}"
    echo "9) Aliases"
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
echo -e "${GREEN}"
cat << "EOF"
             ,----------------,              ,---------,
        ,-----------------------,          ,"        ,"|
      ,"                      ,"|        ,"        ,"  |
     +-----------------------+  |      ,"        ,"    |
     |  .-----------------.  |  |     +---------+      |
     |  |                 |  |  |     | -==----'|      |
     |  |  GNU/GRUB       |  |  |     |         |      |
     |  |  Arch Linux     |  |  |/----|`---=    |      |
     |  |                 |  |  |   ,/|==== ooo |      ;
     |  |                 |  |  |  // |(((( [33]|    ,"
     |  `-----------------'  |," .;'| |((((     |  ,"
     +-----------------------+  ;;  | |         |,"     -FINISH-
        /_)______________(_/  //'   | +---------+
   ___________________________/___  `,
  /  oooooooooooooooo  .o.  oooo /,   \,"-----------
 / ==ooooooooooooooo==.o.  ooo= //   ,`\--{)B     ,"
/_==__==========__==_ooo__ooo=_/'   /___________,"
`-----------------------------'

EOF
echo -e "${RESET}${CYAN}${T[done]}${RESET}"
echo -e "${YELLOW}${T[total_time]}: ${DURATION}s${RESET}"
