.PHONY: help install build switch decrypt-all decrypt-aws decrypt-ssh encrypt-aws encrypt-ssh test-decrypt clean
.PHONY: macos-install macos-build macos-switch android-install android-build android-switch
.PHONY: check update format show platform generate-key

# Configuration
AGE_KEY := ~/.config/sops/age/keys.txt
AGE_PUBKEY := age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas
DOTFILES := $(shell pwd)

# Platform detection
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
    PLATFORM := macos
else ifeq ($(UNAME),Linux)
    ifeq ($(shell test -d /data/data/com.termux.nix && echo 1),1)
        PLATFORM := android
    else
        PLATFORM := linux
    endif
else
    PLATFORM := unknown
endif

help: ## Show this help message
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║              Dotfiles Management - Multi-Platform              ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Current platform: $(PLATFORM)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Common Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "macOS\|Android" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "macOS Specific:"
	@grep -E '^macos-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Android Specific:"
	@grep -E '^android-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Platform-agnostic targets
install: ## Auto-detect platform and install
ifeq ($(PLATFORM),macos)
	@$(MAKE) macos-install
else ifeq ($(PLATFORM),android)
	@$(MAKE) android-install
else
	@echo "❌ Unknown platform: $(PLATFORM)"
	@exit 1
endif

build: ## Auto-detect platform and build
ifeq ($(PLATFORM),macos)
	@$(MAKE) macos-build
else ifeq ($(PLATFORM),android)
	@$(MAKE) android-build
else
	@echo "❌ Unknown platform: $(PLATFORM)"
	@exit 1
endif

switch: ## Auto-detect platform, decrypt secrets and switch
ifeq ($(PLATFORM),macos)
	@$(MAKE) macos-switch
else ifeq ($(PLATFORM),android)
	@$(MAKE) android-switch
else
	@echo "❌ Unknown platform: $(PLATFORM)"
	@exit 1
endif

# macOS specific targets
macos-install: ## macOS: Install nix-darwin configuration
	@echo "📱 Installing nix-darwin configuration..."
	darwin-rebuild switch --flake .

macos-build: ## macOS: Build nix-darwin configuration (without activation)
	@echo "🔨 Building nix-darwin configuration..."
	darwin-rebuild build --flake .

macos-switch: decrypt-all ## macOS: Decrypt secrets and switch configuration
	@echo "🔄 Switching nix-darwin configuration..."
	darwin-rebuild switch --flake .

# Android specific targets
android-install: ## Android: Install nix-on-droid configuration
	@echo "🤖 Installing nix-on-droid configuration..."
	nix-on-droid switch --flake .

android-build: ## Android: Build nix-on-droid configuration (without activation)
	@echo "🔨 Building nix-on-droid configuration..."
	nix-on-droid build --flake .

android-switch: decrypt-all ## Android: Decrypt secrets and switch configuration
	@echo "🔄 Switching nix-on-droid configuration..."
	nix-on-droid switch --flake .

# Decryption targets (config-driven)
decrypt-all: ## Decrypt all secrets based on secrets.yaml
	@./scripts/decrypt-secrets.sh

# Encryption targets (config-driven)
encrypt-all: ## Encrypt all secrets based on secrets.yaml
	@./scripts/encrypt-secrets.sh

# Legacy individual targets (kept for backwards compatibility)
decrypt-aws: ## Decrypt AWS credentials (uses config)
	@echo "Note: Using config-driven decrypt. Run 'make decrypt-all' for all secrets."
	@./scripts/decrypt-secrets.sh

decrypt-ssh: ## Decrypt SSH keys (uses config)
	@echo "Note: Using config-driven decrypt. Run 'make decrypt-all' for all secrets."
	@./scripts/decrypt-secrets.sh

encrypt-aws: ## Encrypt AWS credentials (uses config)
	@echo "Note: Using config-driven encrypt. Run 'make encrypt-all' for all secrets."
	@./scripts/encrypt-secrets.sh

encrypt-ssh: ## Encrypt SSH keys (uses config)
	@echo "Note: Using config-driven encrypt. Run 'make encrypt-all' for all secrets."
	@./scripts/encrypt-secrets.sh

# Testing
test-decrypt: ## Test decryption to temporary directory
	@echo "Testing decryption..."
	@rm -rf /tmp/dotfiles-test
	@mkdir -p /tmp/dotfiles-test/.config/sops/age
	@cp $(AGE_KEY) /tmp/dotfiles-test/.config/sops/age/
	@HOME=/tmp/dotfiles-test ./scripts/decrypt-secrets.sh
	@echo ""
	@echo "✓ Test successful! Files decrypted to /tmp/dotfiles-test"
	@ls -la /tmp/dotfiles-test/.aws/ 2>/dev/null || true
	@ls -la /tmp/dotfiles-test/.ssh/ 2>/dev/null || true

# Cleanup
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf result result-*
	@rm -rf /tmp/dotfiles-test
	@echo "✓ Cleaned"

# Generate new age key
generate-key: ## Generate a new age encryption key
	@echo "Generating new age key..."
	@mkdir -p ~/.config/sops/age
	@age-keygen -o ~/.config/sops/age/keys.txt
	@echo ""
	@echo "✓ New age key generated at: ~/.config/sops/age/keys.txt"
	@echo ""
	@echo "⚠️  IMPORTANT: Update AGE_PUBKEY in Makefile with the public key shown above!"
	@echo "⚠️  IMPORTANT: Re-encrypt all secrets with the new key!"

# Flake management
check: ## Check flake configuration for errors
	@echo "🔍 Checking flake configuration..."
	nix flake check

update: ## Update flake inputs
	@echo "⬆️  Updating flake inputs..."
	nix flake update

format: ## Format nix files
	@echo "✨ Formatting nix files..."
	nix fmt

show: ## Show flake outputs
	@echo "📋 Flake outputs:"
	@nix flake show

# Platform info
platform: ## Show detected platform
	@echo "Platform: $(PLATFORM)"
	@echo "System: $(UNAME)"
