# tarchy

Ansible playbook for automated Arch Linux setup with Hyprland desktop environment.

## Features

- Automatic hardware detection (CPU, GPU, laptop/desktop)
- Distro-aware package selection (Arch, CachyOS, EndeavourOS)
- Hyprland Wayland compositor with full desktop environment
- AUR support via yay
- Flatpak integration
- Dotfiles management via chezmoi
- System optimizations (zram, TCP BBR, I/O scheduler tuning)

## Requirements

- Arch Linux (or derivative: CachyOS, EndeavourOS)
- Sudo access
- Internet connection

## Quick Start

```bash
# Install Ansible and required collections
sudo pacman -S ansible
ansible-galaxy collection install -r requirements.yml

# Run the playbook
ansible-playbook -i inventory setup.yml --ask-become-pass
```

## Configuration

### Target User

By default, the playbook configures for the current user. Override with:

```bash
ansible-playbook -i inventory setup.yml -e ansible_user=myusername --ask-become-pass
```

### Laptop Power Management

Edit `setup.yml` and change `laptop_power_manager` variable:
- `tlp` (default) - Comprehensive power management
- `auto-cpufreq` - Simpler, automatic tuning

## What Gets Installed

### Official Packages (~80+)
- Core utilities (git, curl, neovim, ripgrep, etc.)
- Audio stack (PipeWire)
- Bluetooth support
- Fonts (Noto family)
- Hyprland + Wayland stack
- Login manager (greetd + tuigreet)
- Terminal (foot), browser (Firefox), file manager (Thunar)

### AUR Packages
- rofi-wayland
- nwg-look
- wlogout

### Flatpak
- Discord

### Hardware-Specific
- Intel/AMD CPU microcode
- NVIDIA/AMD/Intel GPU drivers
- Laptop power management (TLP or auto-cpufreq)

## System Optimizations

- **ZRAM**: Compressed swap (half of RAM, zstd compression)
- **I/O Scheduler**: mq-deadline for NVMe, bfq for SATA
- **TCP BBR**: Better network congestion control
- **EarlyOOM**: Prevents system lockups on low memory

## Dotfiles

Dotfiles are managed via [chezmoi](https://chezmoi.io/) from:
https://github.com/NightmaresOfTheEnd/dotfiles

## License

MIT
