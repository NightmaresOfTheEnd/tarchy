#!/usr/bin/env bash

# =============================================================================
# Hyprland Dotfiles Installation Script
# For vanilla Arch Linux
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
CONFIG_DIR="$HOME/.config"
LOCAL_SHARE="$HOME/.local/share"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Flags
DRY_RUN=false
BACKUP=true
INSTALL_PACKAGES=true
INSTALL_FONTS=true
INSTALL_THEMES=true
INSTALL_CONFIGS=true

AUR_HELPER=""

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_dry() {
    echo -e "${YELLOW}[DRY-RUN]${NC} Would: $1"
}

# =============================================================================
# Pre-flight Checks
# =============================================================================

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        print_error "This script is designed for Arch Linux only!"
        print_info "Detected OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Unknown')"
        exit 1
    fi
    print_success "Arch Linux detected"
}

check_dependencies() {
    local deps=("git" "curl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "Required command '$dep' not found. Please install it first."
            exit 1
        fi
    done
    print_success "Base dependencies found"
}

# =============================================================================
# Package Management
# =============================================================================

install_aur_helper() {
    if command -v paru &> /dev/null; then
        AUR_HELPER="paru"
        print_success "AUR helper found: paru"
    else
        print_warning "paru not found. Installing paru..."
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "Install paru from AUR"
            AUR_HELPER="paru"
        else
            sudo pacman -S --needed --noconfirm base-devel git rust
            local tmpdir
            tmpdir="$(mktemp -d)"
            git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
            (cd "$tmpdir/paru" && makepkg -si --noconfirm)
            rm -rf "$tmpdir"
            AUR_HELPER="paru"
            print_success "paru installed successfully"
        fi
    fi
}

install_packages() {
    print_header "Installing Packages"

    local pacman_file="$DOTFILES_DIR/packages/pacman.txt"
    local aur_file="$DOTFILES_DIR/packages/paru.txt"

    # Install pacman packages
    if [[ -f "$pacman_file" ]]; then
        print_info "Installing official repository packages..."
        local packages
        packages=$(grep -v '^#' "$pacman_file" | grep -v '^$' | tr '\n' ' ')
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "sudo pacman -S --needed $packages"
        else
            sudo pacman -S --needed --noconfirm $packages
            print_success "Official packages installed"
        fi
    fi

    # Install AUR packages
    if [[ -f "$aur_file" ]] && [[ -n "$AUR_HELPER" ]]; then
        print_info "Installing AUR packages..."
        local aur_packages
        aur_packages=$(grep -v '^#' "$aur_file" | grep -v '^$' | tr '\n' ' ')
        if [[ -n "$aur_packages" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "$AUR_HELPER -S --needed $aur_packages"
            else
                $AUR_HELPER -S --needed --noconfirm $aur_packages
                print_success "AUR packages installed"
            fi
        fi
    fi
}

# =============================================================================
# Backup Functions
# =============================================================================

backup_existing() {
    local target="$1"
    local name
    name=$(basename "$target")

    if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$BACKUP" == true ]]; then
            mkdir -p "$BACKUP_DIR"
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "Backup $target -> $BACKUP_DIR/$name"
            else
                mv "$target" "$BACKUP_DIR/$name"
                print_info "Backed up: $target"
            fi
        else
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "Remove $target"
            else
                rm -rf "$target"
            fi
        fi
    fi
}

# =============================================================================
# Symlink Functions
# =============================================================================

create_symlink() {
    local source="$1"
    local target="$2"

    # Create parent directory if needed
    local parent_dir
    parent_dir=$(dirname "$target")
    if [[ ! -d "$parent_dir" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "mkdir -p $parent_dir"
        else
            mkdir -p "$parent_dir"
        fi
    fi

    # Backup existing
    backup_existing "$target"

    # Create symlink
    if [[ "$DRY_RUN" == true ]]; then
        print_dry "ln -sf $source -> $target"
    else
        ln -sf "$source" "$target"
        print_success "Linked: $target"
    fi
}

# =============================================================================
# Installation Functions
# =============================================================================

install_configs() {
    print_header "Installing Configuration Files"

    # List of config directories to symlink
    local configs=(
        "hypr"
        "waybar"
        "rofi"
        "wofi"
        "mako"
        "wlogout"
        "foot"
        "ranger"
        "ncmpcpp"
        "geany"
        "vim"
    )

    for config in "${configs[@]}"; do
        if [[ -d "$DOTFILES_DIR/config/$config" ]]; then
            create_symlink "$DOTFILES_DIR/config/$config" "$CONFIG_DIR/$config"
        fi
    done

    # Create Screenshots directory
    if [[ "$DRY_RUN" == true ]]; then
        print_dry "mkdir -p ~/Pictures/Screenshots"
    else
        mkdir -p ~/Pictures/Screenshots
        print_success "Created ~/Pictures/Screenshots"
    fi
}

install_fonts() {
    print_header "Installing Fonts"

    local font_dir="$LOCAL_SHARE/fonts"

    if [[ "$DRY_RUN" == true ]]; then
        print_dry "mkdir -p $font_dir"
        print_dry "Copy fonts from $DOTFILES_DIR/fonts/ to $font_dir/"
        print_dry "fc-cache -fv"
    else
        mkdir -p "$font_dir"
        cp -r "$DOTFILES_DIR/fonts/"* "$font_dir/" 2>/dev/null || true
        fc-cache -fv > /dev/null 2>&1
        print_success "Fonts installed and cache refreshed"
    fi
}

install_themes() {
    print_header "Installing GTK Themes, Icons, and Cursors"

    local theme_dir="$LOCAL_SHARE/themes"
    local icon_dir="$LOCAL_SHARE/icons"

    # GTK Themes
    if [[ -d "$DOTFILES_DIR/themes/gtk" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "mkdir -p $theme_dir"
            print_dry "Copy GTK themes to $theme_dir/"
        else
            mkdir -p "$theme_dir"
            cp -r "$DOTFILES_DIR/themes/gtk/"* "$theme_dir/" 2>/dev/null || true
            print_success "GTK themes installed"
        fi
    fi

    # Icon themes
    if [[ -d "$DOTFILES_DIR/icons" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "mkdir -p $icon_dir"
            print_dry "Copy icon themes to $icon_dir/"
        else
            mkdir -p "$icon_dir"
            cp -r "$DOTFILES_DIR/icons/"* "$icon_dir/" 2>/dev/null || true
            print_success "Icon themes installed"
        fi
    fi

    # Cursor themes
    if [[ -d "$DOTFILES_DIR/cursors" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "Copy cursor themes to $icon_dir/"
        else
            mkdir -p "$icon_dir"
            cp -r "$DOTFILES_DIR/cursors/"* "$icon_dir/" 2>/dev/null || true
            print_success "Cursor themes installed"
        fi
    fi
}

install_sddm_theme() {
    print_header "Installing SDDM Theme"

    local sddm_theme_dir="/usr/share/sddm/themes/sugar-candy"
    local sddm_conf_dir="/etc/sddm.conf.d"
    local wallpaper_src="$HOME/.config/hypr/wallpapers/wallpaper.png"
    local theme_conf_src="$DOTFILES_DIR/config/sddm/theme.conf"
    local sddm_conf_src="$DOTFILES_DIR/config/sddm/sddm.conf"

    # Check if sugar-candy theme is installed
    if [[ ! -d "$sddm_theme_dir" ]]; then
        print_warning "SDDM sugar-candy theme not found. Skipping SDDM theme setup."
        print_info "Install it with: paru -S sddm-sugar-candy-git"
        return
    fi

    # Copy SDDM configuration
    print_info "Setting sugar-candy as default SDDM theme..."
    if [[ "$DRY_RUN" == true ]]; then
        print_dry "sudo mkdir -p $sddm_conf_dir"
        print_dry "sudo cp $sddm_conf_src $sddm_conf_dir/theme.conf"
    else
        sudo mkdir -p "$sddm_conf_dir"
        sudo cp "$sddm_conf_src" "$sddm_conf_dir/theme.conf"
        print_success "SDDM theme set to sugar-candy"
    fi

    # Copy wallpaper to theme directory
    if [[ -f "$wallpaper_src" ]]; then
        print_info "Copying wallpaper to SDDM theme..."
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "sudo cp $wallpaper_src $sddm_theme_dir/wallpaper.png"
        else
            sudo cp "$wallpaper_src" "$sddm_theme_dir/wallpaper.png"
            print_success "Wallpaper copied to SDDM theme"
        fi
    else
        print_warning "Wallpaper not found at $wallpaper_src"
    fi

    # Copy theme configuration
    if [[ -f "$theme_conf_src" ]]; then
        print_info "Applying theme configuration..."
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "sudo cp $theme_conf_src $sddm_theme_dir/theme.conf"
        else
            sudo cp "$theme_conf_src" "$sddm_theme_dir/theme.conf"
            print_success "SDDM theme configured with Catppuccin colors"
        fi
    fi

    print_success "SDDM theme installation complete"
}

install_gpu_drivers() {
    print_header "GPU Driver Installation"

    echo -e "Do you want to install GPU drivers?"
    echo -e "  1) AMD (mesa, vulkan-radeon, libva-mesa-driver)"
    echo -e "  2) Intel (mesa, vulkan-intel, intel-media-driver)"
    echo -e "  3) Nvidia (nvidia, nvidia-utils)"
    echo -e "  4) Skip (I'll install drivers myself)"
    echo ""
    read -p "Select option [1-4]: " -n 1 -r gpu_choice
    echo ""

    case $gpu_choice in
        1)
            print_info "Installing AMD GPU drivers..."
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "sudo pacman -S --needed mesa vulkan-radeon libva-mesa-driver"
            else
                sudo pacman -S --needed --noconfirm mesa vulkan-radeon libva-mesa-driver
                print_success "AMD drivers installed"
            fi
            ;;
        2)
            print_info "Installing Intel GPU drivers..."
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "sudo pacman -S --needed mesa vulkan-intel intel-media-driver"
            else
                sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver
                print_success "Intel drivers installed"
            fi
            ;;
        3)
            print_info "Installing Nvidia GPU drivers..."
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "sudo pacman -S --needed nvidia nvidia-utils"
            else
                sudo pacman -S --needed --noconfirm nvidia nvidia-utils
                print_success "Nvidia drivers installed"
                print_warning "You may need additional Nvidia configuration for Hyprland"
                print_info "See: https://wiki.hyprland.org/Nvidia/"
            fi
            ;;
        4|*)
            print_info "Skipping GPU driver installation"
            ;;
    esac
}

enable_services() {
    print_header "Enabling System Services"

    # User services (audio)
    local user_services=(
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
    )

    # System services (boot with system)
    local system_services=(
        "bluetooth"
        "NetworkManager"
        "acpid"
        "power-profiles-daemon"
        "tailscaled"
    )

    # Display manager
    local display_manager="sddm"

    print_info "Enabling user services (audio)..."
    for service in "${user_services[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "systemctl --user enable --now $service"
        else
            systemctl --user enable --now "$service" 2>/dev/null || print_warning "Could not enable $service"
        fi
    done

    print_info "Enabling system services..."
    for service in "${system_services[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            print_dry "sudo systemctl enable --now $service"
        else
            sudo systemctl enable --now "$service" 2>/dev/null || print_warning "Could not enable $service"
        fi
    done

    # Enable display manager (SDDM)
    print_info "Enabling display manager (SDDM)..."
    if [[ "$DRY_RUN" == true ]]; then
        print_dry "sudo systemctl enable $display_manager"
    else
        sudo systemctl enable "$display_manager" 2>/dev/null || print_warning "Could not enable $display_manager"
        print_success "SDDM enabled (will start on next boot)"
    fi

    print_success "All services enabled"
}

# =============================================================================
# Usage and Argument Parsing
# =============================================================================

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Hyprland dotfiles installation script for Arch Linux.

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be done without making changes
    -n, --no-backup     Don't create backups of existing files

    --no-packages       Skip package installation
    --no-fonts          Skip font installation
    --no-themes         Skip theme/icon/cursor installation
    --no-configs        Skip config file installation

    --packages-only     Only install packages
    --fonts-only        Only install fonts
    --themes-only       Only install themes
    --configs-only      Only install config files

EXAMPLES:
    $(basename "$0")                    # Full installation
    $(basename "$0") --dry-run          # Preview changes
    $(basename "$0") --configs-only     # Only symlink configs
    $(basename "$0") --no-packages      # Skip package installation

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                print_warning "DRY RUN MODE - No changes will be made"
                ;;
            -n|--no-backup)
                BACKUP=false
                ;;
            --no-packages)
                INSTALL_PACKAGES=false
                ;;
            --no-fonts)
                INSTALL_FONTS=false
                ;;
            --no-themes)
                INSTALL_THEMES=false
                ;;
            --no-configs)
                INSTALL_CONFIGS=false
                ;;
            --packages-only)
                INSTALL_FONTS=false
                INSTALL_THEMES=false
                INSTALL_CONFIGS=false
                ;;
            --fonts-only)
                INSTALL_PACKAGES=false
                INSTALL_THEMES=false
                INSTALL_CONFIGS=false
                ;;
            --themes-only)
                INSTALL_PACKAGES=false
                INSTALL_FONTS=false
                INSTALL_CONFIGS=false
                ;;
            --configs-only)
                INSTALL_PACKAGES=false
                INSTALL_FONTS=false
                INSTALL_THEMES=false
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"

    echo -e "${BOLD}${CYAN}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║           Hyprland Dotfiles Installation                  ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Pre-flight checks
    print_header "Pre-flight Checks"
    check_arch
    check_dependencies

    # Install AUR helper if needed
    if [[ "$INSTALL_PACKAGES" == true ]]; then
        install_aur_helper
    fi

    # Ask about GPU drivers
    if [[ "$INSTALL_PACKAGES" == true ]]; then
        install_gpu_drivers
    fi

    # Run installation steps
    [[ "$INSTALL_PACKAGES" == true ]] && install_packages
    [[ "$INSTALL_FONTS" == true ]] && install_fonts
    [[ "$INSTALL_THEMES" == true ]] && install_themes
    [[ "$INSTALL_CONFIGS" == true ]] && install_configs

    # Install SDDM theme (only if packages were installed)
    if [[ "$INSTALL_PACKAGES" == true ]]; then
        install_sddm_theme
    fi

    # Enable services (only if packages were installed)
    if [[ "$INSTALL_PACKAGES" == true ]] && [[ "$DRY_RUN" == false ]]; then
        enable_services
    fi

    # Summary
    print_header "Installation Complete"

    if [[ "$BACKUP" == true ]] && [[ -d "$BACKUP_DIR" ]]; then
        print_info "Backups saved to: $BACKUP_DIR"
    fi

    echo -e "\n${GREEN}${BOLD}Installation completed successfully!${NC}"
    echo -e "${BOLD}Services enabled on boot:${NC}"
    echo -e "  - SDDM (display manager)"
    echo -e "  - NetworkManager"
    echo -e "  - Bluetooth"
    echo -e "  - Power profiles daemon"
    echo -e "  - Tailscale"
    echo -e "  - ACPID"
    echo -e "  - Pipewire audio (user session)"
    echo -e "\n${BOLD}Next steps:${NC}"
    echo -e "  1. Reboot your system: ${CYAN}sudo reboot${NC}"
    echo -e "  2. Select ${CYAN}Hyprland${NC} from the SDDM login screen"
    echo -e "\n"
}

main "$@"
