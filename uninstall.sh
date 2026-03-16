#!/usr/bin/env bash

# =============================================================================
# Hyprland Dotfiles Uninstall Script
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOCAL_SHARE="$HOME/.local/share"
BACKUP_BASE="$HOME/.dotfiles-backup"

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
REMOVE_THEMES=false
REMOVE_FONTS=false
REMOVE_PACKAGES=false

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
# Uninstall Functions
# =============================================================================

remove_symlinks() {
    print_header "Removing Configuration Symlinks"

    local configs=(
        "hypr"
        "waybar"
        "rofi"
        "mako"
        "wlogout"
        "foot"
        "ranger"
        "geany"
        "vim"
    )

    for config in "${configs[@]}"; do
        local target="$CONFIG_DIR/$config"
        if [[ -L "$target" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "rm $target"
            else
                rm "$target"
                print_success "Removed symlink: $target"
            fi
        elif [[ -e "$target" ]]; then
            print_warning "Not a symlink (skipped): $target"
        fi
    done
}

remove_themes() {
    print_header "Removing Themes, Icons, and Cursors"

    local theme_dir="$LOCAL_SHARE/themes"
    local icon_dir="$LOCAL_SHARE/icons"

    # GTK Themes
    local themes=("Catppuccin-Mocha" "Manhattan" "White")
    for theme in "${themes[@]}"; do
        if [[ -d "$theme_dir/$theme" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "rm -rf $theme_dir/$theme"
            else
                rm -rf "$theme_dir/$theme"
                print_success "Removed theme: $theme"
            fi
        fi
    done

    # Icon themes
    local icons=("Luv-Folders" "Luv-Folders-Dark")
    for icon in "${icons[@]}"; do
        if [[ -d "$icon_dir/$icon" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "rm -rf $icon_dir/$icon"
            else
                rm -rf "$icon_dir/$icon"
                print_success "Removed icons: $icon"
            fi
        fi
    done

    # Cursor themes
    local cursors=("Qogirr" "Qogirr-Dark" "Sweet")
    for cursor in "${cursors[@]}"; do
        if [[ -d "$icon_dir/$cursor" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "rm -rf $icon_dir/$cursor"
            else
                rm -rf "$icon_dir/$cursor"
                print_success "Removed cursor: $cursor"
            fi
        fi
    done
}

remove_fonts() {
    print_header "Removing Fonts"

    local font_dir="$LOCAL_SHARE/fonts"
    local fonts=(
        "JetBrainsMono"
        "FiraCode"
        "RobotoMono"
        "IosevkaNerdFonts"
        "SymbolsNF.ttf"
        "SymbolsNerdFontComplete.ttf"
    )

    for font in "${fonts[@]}"; do
        if [[ -e "$font_dir/$font" ]]; then
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "rm -rf $font_dir/$font"
            else
                rm -rf "$font_dir/$font"
                print_success "Removed font: $font"
            fi
        fi
    done

    if [[ "$DRY_RUN" == false ]]; then
        fc-cache -fv > /dev/null 2>&1
        print_info "Font cache refreshed"
    fi
}

remove_packages() {
    print_header "Removing Installed Packages"

    local pacman_file="$DOTFILES_DIR/packages/pacman.txt"
    local aur_file="$DOTFILES_DIR/packages/paru.txt"

    # Collect installed packages from the pacman list
    if [[ -f "$pacman_file" ]]; then
        local to_remove=()
        while IFS= read -r pkg; do
            [[ -z "$pkg" || "$pkg" == \#* ]] && continue
            if pacman -Qi "$pkg" &> /dev/null; then
                to_remove+=("$pkg")
            fi
        done < "$pacman_file"

        if [[ ${#to_remove[@]} -gt 0 ]]; then
            print_info "Removing ${#to_remove[@]} official packages..."
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "sudo pacman -Rns ${to_remove[*]}"
            else
                sudo pacman -Rns --noconfirm "${to_remove[@]}" || print_warning "Some packages could not be removed (may be required by other packages)"
                print_success "Official packages removed"
            fi
        else
            print_info "No official packages to remove"
        fi
    fi

    # Collect installed packages from the AUR list
    if [[ -f "$aur_file" ]]; then
        local aur_to_remove=()
        while IFS= read -r pkg; do
            [[ -z "$pkg" || "$pkg" == \#* ]] && continue
            if pacman -Qi "$pkg" &> /dev/null; then
                aur_to_remove+=("$pkg")
            fi
        done < "$aur_file"

        if [[ ${#aur_to_remove[@]} -gt 0 ]]; then
            print_info "Removing ${#aur_to_remove[@]} AUR packages..."
            if [[ "$DRY_RUN" == true ]]; then
                print_dry "sudo pacman -Rns ${aur_to_remove[*]}"
            else
                sudo pacman -Rns --noconfirm "${aur_to_remove[@]}" || print_warning "Some AUR packages could not be removed"
                print_success "AUR packages removed"
            fi
        else
            print_info "No AUR packages to remove"
        fi
    fi
}

list_backups() {
    print_header "Available Backups"

    if [[ -d "$BACKUP_BASE" ]]; then
        local backups
        backups=$(ls -1 "$BACKUP_BASE" 2>/dev/null || true)
        if [[ -n "$backups" ]]; then
            echo "$backups"
            echo ""
            print_info "To restore a backup, copy files from:"
            print_info "  $BACKUP_BASE/<timestamp>/ to ~/.config/"
        else
            print_info "No backups found"
        fi
    else
        print_info "No backup directory found"
    fi
}

# =============================================================================
# Usage and Argument Parsing
# =============================================================================

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Uninstall Hyprland dotfiles.

OPTIONS:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be done without making changes
    --remove-themes     Also remove installed themes, icons, and cursors
    --remove-fonts      Also remove installed fonts
    --remove-packages   Also remove installed packages (pacman + AUR)
    --remove-all        Remove everything (configs, themes, fonts, packages)
    --list-backups      List available configuration backups

EXAMPLES:
    $(basename "$0")                    # Remove config symlinks only
    $(basename "$0") --dry-run          # Preview what would be removed
    $(basename "$0") --remove-all       # Remove everything
    $(basename "$0") --list-backups     # Show available backups

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
            --remove-themes)
                REMOVE_THEMES=true
                ;;
            --remove-fonts)
                REMOVE_FONTS=true
                ;;
            --remove-packages)
                REMOVE_PACKAGES=true
                ;;
            --remove-all)
                REMOVE_THEMES=true
                REMOVE_FONTS=true
                REMOVE_PACKAGES=true
                ;;
            --list-backups)
                list_backups
                exit 0
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
    echo "  ║           Hyprland Dotfiles Uninstall                     ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Confirm
    if [[ "$DRY_RUN" == false ]]; then
        if [[ "$REMOVE_PACKAGES" == true ]]; then
            echo -e "${YELLOW}This will remove your Hyprland configuration symlinks AND uninstall packages.${NC}"
        else
            echo -e "${YELLOW}This will remove your Hyprland configuration symlinks.${NC}"
        fi
        read -p "Are you sure you want to continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Aborted"
            exit 0
        fi
    fi

    # Remove symlinks
    remove_symlinks

    # Remove themes if requested
    [[ "$REMOVE_THEMES" == true ]] && remove_themes

    # Remove fonts if requested
    [[ "$REMOVE_FONTS" == true ]] && remove_fonts

    # Remove packages if requested
    [[ "$REMOVE_PACKAGES" == true ]] && remove_packages

    # Summary
    print_header "Uninstall Complete"

    echo -e "\n${GREEN}${BOLD}Uninstall completed!${NC}"
    echo -e "\nTo restore your old configs, check: ${CYAN}$BACKUP_BASE${NC}"
    echo -e "\n"
}

main "$@"
