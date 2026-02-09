#!/usr/bin/env bash

# =============================================================================
# Paru AUR Helper Installation Script
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

if command -v paru &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} paru is already installed: $(paru --version | head -1)"
    exit 0
fi

echo -e "${BOLD}${CYAN}Installing paru AUR helper...${NC}"

# Install build dependencies
sudo pacman -S --needed --noconfirm base-devel git rust

# Build and install paru
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

git clone https://aur.archlinux.org/paru.git "$TMPDIR/paru"
(cd "$TMPDIR/paru" && makepkg -si --noconfirm)

echo -e "${GREEN}[OK]${NC} paru installed successfully: $(paru --version | head -1)"
