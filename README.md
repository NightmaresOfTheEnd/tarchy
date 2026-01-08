# Hyprland Dotfiles

Personal Hyprland configuration for vanilla Arch Linux. A clean, reproducible desktop environment setup with Catppuccin Mocha theme.

## Features

- Modular Hyprland configuration (17 config files in `config.d/`)
- Vim-style navigation (HJKL for window focus, move, resize)
- Dark/Light theme switching with Catppuccin colors
- Rofi launchers for apps, power menu, network, bluetooth, screenshots
- Waybar status bar with custom modules
- Mako notification daemon
- Hyprlock screen locker with custom layout
- Hypridle for automatic screen dimming, lock, and suspend
- 20+ utility scripts

## Requirements

- Arch Linux (or Arch-based distribution)
- Hyprland-compatible GPU (AMD, Intel, or Nvidia with caveats)

## Prerequisites

Before running the install script:

```bash
# Update system
sudo pacman -Syu

# Install base requirements
sudo pacman -S --needed base-devel git curl
```

The install script will prompt you to install GPU drivers (AMD/Intel/Nvidia) or you can skip and install them yourself.

## Quick Install

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
sudo reboot
```

The script will automatically:
- Install all required packages
- Enable SDDM display manager
- Enable NetworkManager, Bluetooth, audio (Pipewire), power management
- Symlink all configurations
- Install fonts, themes, icons, and cursors

## Installation Options

```bash
# Preview what will be installed (dry run)
./install.sh --dry-run

# Install only configs (skip packages)
./install.sh --no-packages

# Install without creating backups
./install.sh --no-backup

# Install only packages
./install.sh --packages-only

# Install only configs
./install.sh --configs-only
```

## Structure

```
.
├── install.sh              # Installation script
├── uninstall.sh            # Removal script
├── packages/
│   ├── pacman.txt          # Official repo packages
│   ├── aur.txt             # AUR packages
│   └── optional.txt        # Optional packages
├── config/
│   ├── hypr/               # Hyprland config
│   │   ├── config.d/       # Modular config files
│   │   ├── scripts/        # Utility scripts
│   │   ├── theme/          # Theme files
│   │   └── wallpapers/     # Wallpapers
│   ├── waybar/             # Status bar
│   ├── rofi/               # App launcher
│   ├── wofi/               # Alt launcher
│   ├── mako/               # Notifications
│   ├── wlogout/            # Logout menu
│   ├── foot/               # Terminal
│   ├── ranger/             # File manager
│   ├── ncmpcpp/            # Music player
│   └── geany/              # Text editor
├── fonts/                  # Nerd Fonts
├── themes/gtk/             # GTK themes
├── icons/                  # Icon themes
└── cursors/                # Cursor themes
```

## Keybindings

### Window Management
| Key | Action |
|-----|--------|
| `Super + H/J/K/L` | Move focus (vim-style) |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + Ctrl + H/J/K/L` | Resize window |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + Shift + F` | Toggle floating |

### Applications
| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (Foot) |
| `Super + D` | App launcher (Rofi) |
| `Super + E` | File manager (Thunar) |

### Workspaces
| Key | Action |
|-----|--------|
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move window to workspace |

### Session
| Key | Action |
|-----|--------|
| `Super + Ctrl + L` | Lock screen |
| `Super + Shift + X` | Logout menu |

### Media
| Key | Action |
|-----|--------|
| `Print` | Screenshot (region to clipboard) |
| `Shift + Print` | Screenshot (save to file) |
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |

See `config/hypr/config.d/60-key-bindings.conf` for full keybinding list.

## Customization

### Variables
Edit `config/hypr/hyprland.conf` to change default applications:

```bash
$terminal = foot
$launcher = rofi -show drun
$locker = hyprlock
$logout = wlogout
$filemanager = thunar
```

### Theme Colors
Edit `config/hypr/config.d/00-hyprtheme.conf` to change colors and appearance.

### Monitor Configuration
Edit `config/hypr/config.d/20-monitor.conf` for display settings.

## Included Themes

### GTK
- Catppuccin-Mocha (default)
- Manhattan
- White

### Cursors
- Sweet (default)
- Qogirr
- Qogirr-Dark

### Icons
- Luv-Folders
- Luv-Folders-Dark

## Troubleshooting

### Nvidia Users
See [Hyprland Nvidia Guide](https://wiki.hyprland.org/Nvidia/)

Add to `config.d/09-misc.conf`:
```bash
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
```

### Fonts Not Displaying
```bash
fc-cache -fv
```

### Screen Tearing
Enable VRR in `config/hypr/config.d/20-monitor.conf`:
```bash
misc {
    vrr = 1
}
```

## Uninstall

```bash
# Remove config symlinks only
./uninstall.sh

# Remove everything (configs, themes, fonts)
./uninstall.sh --remove-all

# Preview what would be removed
./uninstall.sh --dry-run
```

## License

MIT License - see [LICENSE](LICENSE) file.
