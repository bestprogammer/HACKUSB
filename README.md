# HACK USB

> **Ethical Pentesting USB — one script, every tool, every system.**

```
  ██╗  ██╗ █████╗  ██████╗██╗  ██╗    ██╗   ██╗███████╗██████╗
  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝    ██║   ██║██╔════╝██╔══██╗
  ███████║███████║██║     █████╔╝     ██║   ██║███████╗██████╔╝
  ██╔══██║██╔══██║██║     ██╔═██╗     ██║   ██║╚════██║██╔══██╗
  ██║  ██║██║  ██║╚██████╗██║  ██╗    ╚██████╔╝███████║██████╔╝
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚══════╝╚═════╝
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue.svg)]()
[![Shell](https://img.shields.io/badge/shell-zsh-green.svg)]()

---

> ⚠️ **USE ON YOUR OWN OR AUTHORIZED SYSTEMS ONLY.**
> Unauthorized access is a criminal offense.
> CH: Art. 143bis StGB · DE: §202a StGB · US: CFAA 18 U.S.C. §1030

---

## What is HACK USB?

HACK USB turns any USB stick into a complete portable pentesting toolkit. One wizard-driven setup script installs every tool, clones every repo, downloads wordlists, sets up an encrypted vault, and writes an offline cheatsheet — all automatically.

**Works on:**
- macOS (Homebrew, Apple Silicon + Intel)
- Linux — apt / pacman / dnf / zypper (Kali, Parrot, Ubuntu, Arch, Fedora)
- Windows WSL2 (Ubuntu)
- Windows Native (winget / Chocolatey / Scoop)

---

## Quick Start

```zsh
# macOS (no sudo needed)
zsh hackusb_setup.zsh

# Linux / WSL2
sudo zsh hackusb_setup.zsh
```

The setup wizard walks through 15 steps:

| Step | What happens |
|------|-------------|
| 0 | **Select OS** — macOS / Linux / Windows WSL2 / Windows Native |
| 1 | Auto-detect system & package manager |
| 2 | Choose stick size — 16 / 32 / 64 GB |
| 3 | Set USB mount path |
| 4 | Optional features — Auto-Update, Vault, Ad-Blocker |
| 5 | Format USB stick (skip / ExFAT / encrypted) |
| 6 | Install all runtimes & tools |
| 7 | Create 17-folder directory structure |
| 8 | Clone 34 tool repositories |
| 9 | Download wordlists (rockyou.txt + SecLists) |
| 10 | Write custom scripts |
| 11 | Download 6 ad/malware blocklists |
| 12 | Create VeraCrypt AES-256 vault |
| 13 | Set up auto-update script + optional cronjob |
| 14 | Copy offline cheatsheet |

---

## Installed Tools

### Runtimes (auto-installed)

| Runtime | Version | Installer |
|---------|---------|-----------|
| Python 3 | 3.10+ | brew / apt / dnf |
| Node.js | 20 LTS | nvm / NodeSource |
| Go | 1.21+ | brew / apt / manual |
| Ruby | 3.x | brew / apt |
| Rust | latest | rustup |

### System Tools

| Category | Tools |
|----------|-------|
| Scanning | nmap, masscan, netcat |
| Web | sqlmap, nikto, gobuster, ffuf, feroxbuster |
| Passwords | hashcat, john-jumbo, hydra |
| Wireless | aircrack-ng, hcxtools, hcxdumptool |
| Forensics | binwalk, exiftool, steghide, foremost, volatility3 |
| Exploitation | metasploit-framework |
| Utils | tmux, fzf, bat, ripgrep, jq, git, curl, wget |

### Go Tools (ProjectDiscovery + community)

```
subfinder   httpx       nuclei      naabu       dnsx
katana      ffuf        gobuster    waybackurls assetfinder
gf          anew        qsreplace   unfurl      gau
hakrawler   amass       interactsh-client
```

### Python pip Tools

```
impacket    certipy-ad  bloodhound  pwntools    scapy
shodan      paramiko    requests    mitmproxy   httpx
beautifulsoup4  dnspython   volatility3  cryptography  rich
```

### Ruby Gems

```
wpscan      evil-winrm
```

### Rust / Cargo

```
feroxbuster     rustscan
```

### npm Tools

```
retire      wappalyzer-cli      snyk
```

### Cloned Repositories (34 total)

| Folder | Tools |
|--------|-------|
| `01_recon/` | theHarvester, sherlock, spiderfoot, recon-ng, osrframework |
| `02_scanning/` | nuclei-templates, nmap-vulners, nmap-scripts-extra |
| `03_exploitation/` | sqlmap, XSStrike, commix, BeEF, evilginx2, PayloadsAllTheThings |
| `04_post-exploit/` | PEASS-ng, BloodHound, impacket, NetExec, CrackMapExec, mimikatz |
| `05_wireless/` | wifite2, bettercap, hcxtools, airgeddon |
| `06_password/` | hashcat-utils, john, cupp |
| `07_forensics/` | volatility3, binwalk, autopsy |
| `09_wordlists/` | SecLists, fuzzdb |
| `16_phishing/` | gophish, evilginx3 |

---

## Directory Structure

```
HACKUSB/
├── 01_recon/               OSINT & reconnaissance tools
├── 02_scanning/            Port scanners, NSE scripts
├── 03_exploitation/        Exploit frameworks & payloads
├── 04_post-exploit/        Post-exploitation & lateral movement
├── 05_wireless/            Wi-Fi attack tools
├── 06_password/            Cracking tools & utilities
├── 07_forensics/           Memory & file forensics
├── 08_scripts/             Custom scripts (see below)
├── 09_wordlists/           rockyou.txt, SecLists, fuzzdb
├── 10_cheatsheets/         Offline HTML cheatsheet (index.html)
├── 11_reports/             Scan output & report storage
├── 12_isos/                Kali/Parrot ISO storage (64 GB profile)
├── 13_adblocker/           Blocklists + setup_adblocker.zsh
├── 14_vault/               vault.zsh + secrets.vc (VeraCrypt)
├── 15_loot/                Exfiltrated data & findings
├── 16_phishing/            Phishing frameworks
├── hackusb_setup.zsh       Main setup wizard
├── hackusb_update.zsh      Update all repos + blocklists
└── README.md
```

---

## Custom Scripts

All scripts live in `08_scripts/` and run from anywhere via USB path.

### `auto_recon.zsh` — Full recon in one command
```zsh
zsh 08_scripts/auto_recon.zsh <TARGET> [--full]
# Runs: nmap SYN + all-ports, subfinder, httpx, gobuster, nikto, nuclei
# --full adds: waybackurls, katana JS crawl
# Output saved to 11_reports/recon_TARGET_DATE/
```

### `subdomain_enum.zsh` — Subdomain enumeration pipeline
```zsh
zsh 08_scripts/subdomain_enum.zsh <DOMAIN>
# Chains: subfinder → assetfinder → amass → dnsx → httpx
# Deduplicates, resolves, probes live web servers
```

### `livehosts.py` — Fast ping sweep
```zsh
python3 08_scripts/livehosts.py 192.168.1.0/24
# 150 concurrent threads, saves live_hosts.txt
```

### `port_scan.py` — Pure Python port scanner
```zsh
python3 08_scripts/port_scan.py 192.168.1.1 1-65535
# 500 threads, service detection, no nmap needed
```

### `hashcrack.py` — Auto-detect + crack hash
```zsh
python3 08_scripts/hashcrack.py <HASH> [wordlist]
# Auto-detects MD5/SHA1/SHA256/SHA512 by length
# Defaults to 09_wordlists/rockyou.txt
```

### `revshell_gen.py` — Reverse shell generator (12 variants)
```zsh
python3 08_scripts/revshell_gen.py <LHOST> <LPORT>
# Outputs: Bash TCP/UDP, Python3, PHP, Perl, Ruby,
#          Netcat mkfifo/-e, Socat, PowerShell Base64
```

### `install_on_pc.zsh` — Deploy tools on any machine
```zsh
zsh 08_scripts/install_on_pc.zsh
# Run from USB on any PC to install all pentest tools
# Profiles: Quick (5 min) / Standard (15 min) / Full (30+ min)
# Supports: macOS, Linux (apt/pacman/dnf), Windows WSL2/winget
```

---

## Ad-Blocker

Six blocklists, all with CDN fallback:

| List | Domains | Source |
|------|---------|--------|
| Hagezi Light | ~50K | Low false-positives |
| **Hagezi Pro** ★ | ~100K | Recommended |
| Hagezi Malware | ~80K | Phishing + malware |
| Hagezi Ultimate | ~250K | Aggressive |
| Steven Black | ~100K | Ads + malware |
| oisd basic | ~50K | Clean, low false-positives |
| **Combo** (default) | ~200K+ | Pro + Malware + Steven Black + oisd |

```zsh
# Enable (choose profile interactively)
sudo zsh 13_adblocker/setup_adblocker.zsh

# Status / disable / update
sudo zsh 13_adblocker/setup_adblocker.zsh --status
sudo zsh 13_adblocker/setup_adblocker.zsh --restore
sudo zsh 13_adblocker/setup_adblocker.zsh --update
```

Works on macOS (`/etc/hosts` + `dscacheutil`), Linux (`resolvectl`/`nscd`), Windows WSL2.

---

## Encrypted Vault

AES-256-XTS + SHA-512 key derivation via VeraCrypt.

```zsh
zsh 14_vault/vault.zsh mount     # Open → /Volumes/VAULT (macOS) or /mnt/hackusb_vault (Linux)
zsh 14_vault/vault.zsh unmount   # Close — always before removing stick!
zsh 14_vault/vault.zsh status    # Check if mounted
zsh 14_vault/vault.zsh backup    # Copy secrets.vc → secrets.vc.bak.DATE
```

What to store: SSH keys, VPN configs, API keys, pentest reports, credentials.

---

## Auto-Update

```zsh
sudo zsh hackusb_update.zsh           # Update changed repos + all blocklists
sudo zsh hackusb_update.zsh --force   # Re-download everything including rockyou.txt
```

Updates: all git repos (`git pull --ff-only`, auto hard-reset on conflict), rockyou.txt, all 6 blocklists, rebuilds `hosts_combined.txt`.

Optional monthly cronjob (offered during setup):
```
0 3 1 * * sudo zsh /Volumes/HACKUSB/hackusb_update.zsh --force
```

---

## Offline Cheatsheet

Open `10_cheatsheets/index.html` in any browser — no internet needed.

Sections: Quick Start · USB Format · Install on PC · Node.js · Python · Go Tools · Recon · Scanning · Web Hacking · Exploitation · Post-Exploit · Wireless · Passwords · Reverse Shells · PrivEsc · Forensics · Ad-Blocker · Vault · Auto-Update

**OS switcher** at the top toggles all commands between macOS / Linux / Windows.

```zsh
# Open cheatsheet:
open /Volumes/HACKUSB/10_cheatsheets/index.html          # macOS
xdg-open /media/$USER/HACKUSB/10_cheatsheets/index.html  # Linux
start E:\HACKUSB\10_cheatsheets\index.html                # Windows
```

---

## USB Profiles

| Profile | Stick | Needed | What's included |
|---------|-------|--------|----------------|
| `minimal` | 16 GB | ~8 GB | Base tools, rockyou, cheatsheet |
| `standard` | 32 GB | ~18 GB | + SecLists, wireless, post-exploit |
| `full` | 64 GB | ~26 GB | + ISOs (Kali/Parrot), everything |

---

## Files on USB

```
hackusb_setup.zsh       → Run once to set everything up
hackusb_update.zsh      → Run monthly to keep tools current
hackusb_cheatsheet.html → Copy next to setup.zsh before running
```

---

## Legal

This project is intended for:
- Authorized penetration testing
- CTF competitions
- Security research on your own systems
- Educational purposes

**Do not use on systems you do not own or have explicit written permission to test.**

| Jurisdiction | Law |
|---|---|
| Switzerland | Art. 143bis StGB |
| Germany | §202a StGB |
| United States | CFAA 18 U.S.C. §1030 |
| European Union | Directive 2013/40/EU |

---

## License

MIT — see [LICENSE](LICENSE)

---

*HACK USB — portable, offline, always ready.*
