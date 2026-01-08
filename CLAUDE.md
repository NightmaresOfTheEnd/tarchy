# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Hyprland Dotfiles** - Reproducible Arch Linux desktop configuration with Hyprland window manager. This is a shell script + configuration file project, not a traditional software codebase.

**Core Stack:** Hyprland (Wayland compositor), Waybar (status bar), Rofi (launcher), Foot (terminal), Mako (notifications)

## Installation Commands

```bash
# Full installation (packages, configs, fonts, themes)
./install.sh

# Preview installation without changes
./install.sh --dry-run

# Options
./install.sh --no-packages    # Skip package installation
./install.sh --no-backup      # Install without backups
./install.sh --packages-only  # Only install packages
./install.sh --configs-only   # Only install configs

# Uninstall
./uninstall.sh               # Remove config symlinks
./uninstall.sh --remove-all  # Remove everything
```

## Architecture

### Modular Configuration Pattern
The main Hyprland config (`config/hypr/hyprland.conf`) sources all files from `config/hypr/config.d/` using numbered prefixes (00-70) for load ordering:
- `00-hyprtheme.conf` - Color variables (Catppuccin palette)
- `01-09` - General settings, decoration, animations, input, cursor
- `20-monitor.conf` - Display configuration
- `30-40` - Layout settings (dwindle, master)
- `50-window-rules.conf` - Window-specific rules
- `60-key-bindings.conf` - Keyboard shortcuts
- `70-permissions.conf` - Permission settings

### Script Organization
26 utility scripts in `config/hypr/scripts/` handle system tasks:
- `startup` - Launches session services
- `rofi_*` - Rofi menu launchers (network, bluetooth, powermenu, screenshot)
- `volume`, `brightness` - Media controls with notifications
- `screenshot`, `colorpicker` - Utilities

### Theme System
Three themes managed via `config/hypr/theme/`:
- Dark (default), Light, and Pywal-generated from wallpapers
- Theme switching affects: terminals, waybar, rofi, mako, wlogout

### Configuration Languages
- **Hyprland:** Native conf format with `$variable` substitution
- **Waybar:** JSON with module definitions
- **Rofi:** RASI format (CSS-like)
- **Terminal/Mako:** INI format

## Key Conventions

### Keybinding Pattern
- `Super+H/J/K/L` - Vim-style window navigation
- `Super+Shift+*` - Move/modify windows
- `Super+Ctrl+*` - Resize windows

### Variables in Main Config
```conf
$terminal = foot
$launcher = ~/.config/hypr/scripts/rofi_launcher
$locker = hyprlock
$filemanager = thunar
```

### Script Standards
All scripts use `set -euo pipefail` for strict error handling and include colored output helpers.

### Package Lists
- `packages/pacman.txt` - Official Arch packages
- `packages/aur.txt` - AUR packages
- `packages/optional.txt` - Optional extras

## File Locations

- Symlinked to `~/.config/hypr/`, `~/.config/waybar/`, etc.
- Fonts install to `~/.local/share/fonts/`
- Themes install to `~/.local/share/themes/`
- Backups go to `~/.dotfiles-backup/`

## Making Changes

- **Config changes:** Edit files in `config/hypr/config.d/`
- **New scripts:** Add to `config/hypr/scripts/` with executable permission
- **Theme changes:** Use `config/hypr/theme/theme.sh` for application-wide updates
- **New packages:** Add to appropriate file in `packages/`
