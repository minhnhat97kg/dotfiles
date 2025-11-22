.PHONY: help install build switch encrypt decrypt encrypt-ssh encrypt-aws encrypt-git decrypt-ssh decrypt-aws decrypt-git test clean check update format deps darwin android

# Configuration
SECRETS_CONFIG ?= ./secrets/config.yaml

# Platform detection
PLATFORM := $(shell uname -s | sed 's/Darwin/macos/' | sed 's/Linux/android/' )

help: ## Show available commands
	@echo "Dotfiles Management (Platform: $(PLATFORM))"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo ""
	@echo "Configuration:"
	@echo "  SECRETS_CONFIG=$(SECRETS_CONFIG)"

deps: ## Install required dependencies (yq-go, age)
	@echo "Installing dependencies..."
	@if ! command -v yq-go &> /dev/null && ! command -v yq &> /dev/null; then \
		echo "  Installing yq-go..."; \
		nix profile install nixpkgs#yq-go; \
	else \
		echo "  ✓ yq already installed"; \
	fi
	@if ! command -v age &> /dev/null; then \
		echo "  Installing age..."; \
		nix profile install nixpkgs#age; \
	else \
		echo "  ✓ age already installed"; \
	fi
	@echo "✓ All dependencies installed"

# Main targets
install: ## Install configuration (auto-detect platform)
ifeq ($(PLATFORM),macos)
	darwin-rebuild switch --flake .
	@echo ""
	@echo "Checking yabai scripting addition LaunchDaemon..."
	@if [ -f /Library/LaunchDaemons/org.nixos.yabai-sa.plist ]; then \
		sudo launchctl bootout system/org.nixos.yabai-sa 2>/dev/null || true; \
		sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.yabai-sa.plist; \
		sudo launchctl enable system/org.nixos.yabai-sa; \
		echo "✓ yabai scripting addition LaunchDaemon loaded"; \
	fi
else
	nix-on-droid switch --flake .
endif

darwin: ## Install on macOS (nix-darwin)
	darwin-rebuild switch --flake .
	@echo ""
	@echo "Checking yabai scripting addition LaunchDaemon..."
	@if [ -f /Library/LaunchDaemons/org.nixos.yabai-sa.plist ]; then \
		sudo launchctl bootout system/org.nixos.yabai-sa 2>/dev/null || true; \
		sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.yabai-sa.plist; \
		sudo launchctl enable system/org.nixos.yabai-sa; \
		echo "✓ yabai scripting addition LaunchDaemon loaded"; \
	fi

android: ## Install on Android (nix-on-droid)
	nix-on-droid switch --flake .

build: ## Build configuration without installing
ifeq ($(PLATFORM),macos)
	darwin-rebuild build --flake .
else
	nix-on-droid build --flake .
endif

switch: install ## Switch configuration

# Encryption targets
encrypt: ## Encrypt all secrets based on config file
	@./scripts/secrets-sync.sh

encrypt-custom: ## Encrypt with custom config (usage: make encrypt-custom CONFIG=/path/to/config.yaml)
	@if [ -z "$(CONFIG)" ]; then echo "Error: CONFIG not specified. Usage: make encrypt-custom CONFIG=/path/to/config.yaml"; exit 1; fi
	@./scripts/secrets-sync.sh --config $(CONFIG)

# Decryption targets
decrypt: ## Decrypt all secrets based on config file
	@./scripts/secrets-decrypt.sh

decrypt-yes: ## Decrypt all secrets without confirmation prompt
	@./scripts/secrets-decrypt.sh --yes

decrypt-custom: ## Decrypt with custom config (usage: make decrypt-custom CONFIG=/path/to/config.yaml)
	@if [ -z "$(CONFIG)" ]; then echo "Error: CONFIG not specified. Usage: make decrypt-custom CONFIG=/path/to/config.yaml"; exit 1; fi
	@./scripts/secrets-decrypt.sh --config $(CONFIG)

