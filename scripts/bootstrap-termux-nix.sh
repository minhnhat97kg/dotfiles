#!/data/data/com.termux/files/usr/bin/bash
# Bootstrap Nix installation in regular Termux (without nix-on-droid app)
#
# Usage: bash bootstrap-termux-nix.sh
#
# This script installs vanilla Nix in Termux and configures it to use
# the dotfiles repository with home-manager for a lightweight setup.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}Warning:${NC} $*"; }
error() { echo -e "${RED}Error:${NC} $*" >&2; exit 1; }

# Check we're in Termux
if [ ! -d "/data/data/com.termux" ]; then
    error "This script must be run in Termux (not nix-on-droid)"
fi

# Check if nix-on-droid is installed
if [ -d "/data/data/com.termux.nix" ]; then
    warn "nix-on-droid appears to be installed. This script is for vanilla Termux."
    warn "If you want to use nix-on-droid instead, use 'make android' from the dotfiles repo."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

log "Termux Nix Bootstrap Script"
echo "This will install Nix in Termux and configure it with your dotfiles."
echo ""

# Step 1: Install Termux dependencies
log "Step 1: Installing Termux prerequisites..."
pkg update -y
pkg install -y \
    wget \
    curl \
    git \
    gnupg \
    xz-utils \
    which

# Step 2: Install Nix
if command -v nix &> /dev/null; then
    log "Nix is already installed ($(nix --version))"
else
    log "Step 2: Installing Nix..."

    # Create temporary directory
    TMPDIR="${PREFIX}/tmp"
    mkdir -p "$TMPDIR"
    export TMPDIR

    # Use the official single-user Nix installer
    log "Downloading Nix installer..."
    curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh

    log "Running Nix installer (single-user mode)..."
    sh /tmp/nix-install.sh --no-daemon

    # Source Nix profile
    . $HOME/.nix-profile/etc/profile.d/nix.sh

    log "Nix installed successfully: $(nix --version)"
fi

# Step 3: Enable flakes and nix-command
log "Step 3: Configuring Nix..."
mkdir -p $HOME/.config/nix

cat > $HOME/.config/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
warn-dirty = false
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
EOF

log "Nix configuration created"

# Step 4: Clone dotfiles if not present
if [ ! -d "$HOME/projects/dotfiles" ]; then
    log "Step 4: Cloning dotfiles repository..."
    mkdir -p $HOME/projects
    cd $HOME/projects

    read -p "Enter your dotfiles git URL (or press Enter for default): " REPO_URL
    REPO_URL=${REPO_URL:-"https://github.com/yourusername/dotfiles.git"}

    git clone "$REPO_URL" dotfiles
    cd dotfiles
else
    log "Step 4: Dotfiles already present at $HOME/projects/dotfiles"
    cd $HOME/projects/dotfiles
fi

# Step 5: Install home-manager
log "Step 5: Installing home-manager..."

# Source nix profile to ensure nix commands are available
. $HOME/.nix-profile/etc/profile.d/nix.sh

# Install home-manager using the flake
nix run home-manager/master -- init --switch ~/projects/dotfiles#termux

log "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "1. Restart your shell or run: source ~/.nix-profile/etc/profile.d/nix.sh"
echo "2. Go to dotfiles: cd ~/projects/dotfiles"
echo "3. Apply configuration: make termux"
echo ""
echo "The configuration uses a minimal package set (android-lite) optimized for battery life."
echo "Heavy development tools are available via: nix develop ~/dotfiles#<shell-name>"
