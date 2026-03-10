.PHONY: help install build switch encrypt encrypt-custom decrypt decrypt-yes decrypt-custom deps update format check clean gen-key darwin android linux wsl termux check-age-key

# Configuration
SECRETS_CONFIG ?= ./secrets/config.yaml

# Detect platform: macos, wsl, termux, android, linux
_UNAME := $(shell uname -s)
_IS_WSL := $(shell grep -qi microsoft /proc/version 2>/dev/null && echo yes || echo no)
_IS_TERMUX := $(shell [ -d /data/data/com.termux ] && echo yes || echo no)
_IS_DROID := $(shell command -v nix-on-droid > /dev/null 2>&1 && echo yes || echo no)

ifeq ($(_UNAME),Darwin)
  PLATFORM := macos
else ifeq ($(_IS_WSL),yes)
  PLATFORM := wsl
else ifeq ($(_IS_TERMUX),yes)
  PLATFORM := termux
else ifeq ($(_IS_DROID),yes)
  PLATFORM := android
else
  PLATFORM := linux
endif

help: ## Show available commands
	@echo "Dotfiles Management (Platform: $(PLATFORM))"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
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

gen-key: ## Generate age key for secrets encryption
	@mkdir -p ~/.config/sops/age
	@age-keygen -o ~/.config/sops/age/keys.txt
	@echo "✓ Age key generated at ~/.config/sops/age/keys.txt"
	@echo "  Public key:"
	@age-keygen -y ~/.config/sops/age/keys.txt

check-age-key: ## Check age key exists, prompt to set up if missing
	@./scripts/check-age-key.sh

# Main targets
install: check-age-key ## Install configuration (auto-detect platform)
ifeq ($(PLATFORM),macos)
	sudo darwin-rebuild switch --flake .
	@echo ""
else ifeq ($(PLATFORM),android)
	nix-on-droid switch --flake .
else
	home-manager switch --flake .#$(PLATFORM)
endif

darwin: check-age-key ## Install on macOS (nix-darwin)
	sudo darwin-rebuild switch --flake .
	@echo ""

android: check-age-key ## Install on Android (nix-on-droid)
	nix-on-droid switch --flake .

linux: check-age-key ## Install on Ubuntu Linux (home-manager)
	home-manager switch --flake .#ubuntu

wsl: check-age-key ## Install on WSL (home-manager)
	home-manager switch --flake .#wsl

termux: check-age-key ## Install on Termux (home-manager, aarch64)
	home-manager switch --flake .#termux

build: ## Build configuration without installing
ifeq ($(PLATFORM),macos)
	darwin-rebuild build --flake .
else ifeq ($(PLATFORM),android)
	nix-on-droid build --flake .
else
	home-manager build --flake .#$(PLATFORM)
endif

switch: install ## Switch configuration (alias for install)

update: ## Update flake inputs
	nix flake update

format: ## Format all nix files with alejandra
	nix fmt

check: ## Validate flake configuration
	nix flake check

clean: ## Remove build artifacts
	rm -f result result-*

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

secret-edit: ## Interactively enter/update a secret and encrypt it
	@./scripts/secrets-edit.sh
