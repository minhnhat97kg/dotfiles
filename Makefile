.PHONY: help install build switch decrypt encrypt test clean check update format deps darwin android

# Configuration - can override via: make decrypt AGE_KEY=/path/to/key.txt
AGE_KEY ?= ~/.config/sops/age/keys.txt
AGE_PUBKEY := age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas

# Platform detection
PLATFORM := $(shell uname -s | sed 's/Darwin/macos/' | sed 's/Linux/android/' )

help: ## Show available commands
	@echo "Dotfiles Management (Platform: $(PLATFORM))"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Options:"
	@echo "  AGE_KEY=/path/to/key.txt  Override age key location"

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
install: decrypt ## Decrypt and install configuration (auto-detect platform)
ifeq ($(PLATFORM),macos)
	darwin-rebuild switch --flake .
else
	nix-on-droid switch --flake .
endif

darwin: decrypt ## Install on macOS (nix-darwin)
	darwin-rebuild switch --flake .

android: ## Install on Android (nix-on-droid)
	nix-on-droid switch --flake .

build: ## Build configuration without installing
ifeq ($(PLATFORM),macos)
	darwin-rebuild build --flake .
else
	nix-on-droid build --flake .
endif

switch: decrypt install ## Decrypt secrets and switch configuration

decrypt: check-deps ## Decrypt all secrets (use AGE_KEY=/path to override)
	@expanded_key=$$(echo "$(AGE_KEY)" | sed "s|^~|$$HOME|"); \
	if [ ! -f "$$expanded_key" ]; then \
		echo "❌ Age key not found at: $(AGE_KEY)"; \
		echo "   Generate one with: make gen-key"; \
		echo "   Or specify: make decrypt AGE_KEY=/path/to/key.txt"; \
		exit 1; \
	fi
	@AGE_KEY="$(AGE_KEY)" ./scripts/decrypt-secrets.sh

encrypt: check-deps ## Encrypt all secrets (use AGE_KEY=/path to override)
	@expanded_key=$$(echo "$(AGE_KEY)" | sed "s|^~|$$HOME|"); \
	if [ ! -f "$$expanded_key" ]; then \
		echo "❌ Age key not found at: $(AGE_KEY)"; \
		exit 1; \
	fi
	@AGE_KEY="$(AGE_KEY)" ./scripts/encrypt-secrets.sh

# Internal target - check and auto-install dependencies
check-deps:
	@if ! command -v yq-go &> /dev/null && ! command -v yq &> /dev/null; then \
		echo "⚠️  yq-go not found, installing..."; \
		nix profile install nixpkgs#yq-go; \
	fi
	@if ! command -v age &> /dev/null; then \
		echo "⚠️  age not found, installing..."; \
		nix profile install nixpkgs#age; \
	fi

test: ## Test decryption in /tmp
	@rm -rf /tmp/dotfiles-test
	@mkdir -p /tmp/dotfiles-test/.config/sops/age
	@cp $(AGE_KEY) /tmp/dotfiles-test/.config/sops/age/
	@AGE_KEY=/tmp/dotfiles-test/.config/sops/age/keys.txt HOME=/tmp/dotfiles-test ./scripts/decrypt-secrets.sh
	@echo "✓ Test complete: /tmp/dotfiles-test"

clean: ## Clean build artifacts
	@rm -rf result result-* /tmp/dotfiles-test

gen-key: ## Generate or import age encryption key
	@echo "Choose an option:"
	@echo "  1) Generate new age key"
	@echo "  2) Import existing age key"
	@read -p "Enter choice [1/2]: " choice; \
	mkdir -p ~/.config/sops/age; \
	if [ "$$choice" = "1" ]; then \
		age-keygen -o ~/.config/sops/age/keys.txt; \
		echo ""; \
		echo "⚠️  Update AGE_PUBKEY in Makefile with the public key shown above!"; \
		echo "⚠️  Re-encrypt all secrets with: make encrypt"; \
	elif [ "$$choice" = "2" ]; then \
		echo ""; \
		echo "Paste your age private key (it should start with 'AGE-SECRET-KEY-'):"; \
		read -r age_key; \
		echo "$$age_key" > ~/.config/sops/age/keys.txt; \
		chmod 600 ~/.config/sops/age/keys.txt; \
		echo ""; \
		echo "✓ Age key saved to: ~/.config/sops/age/keys.txt"; \
		echo ""; \
		echo "Now extracting public key..."; \
		pubkey=$$(age-keygen -y ~/.config/sops/age/keys.txt 2>/dev/null || echo ""); \
		if [ -n "$$pubkey" ]; then \
			echo "Public key: $$pubkey"; \
			echo ""; \
			echo "⚠️  Update AGE_PUBKEY in Makefile with: $$pubkey"; \
		else \
			echo "⚠️  Could not extract public key. Please verify the key is valid."; \
		fi; \
	else \
		echo "Invalid choice"; \
		exit 1; \
	fi

check: ## Check flake configuration
	nix flake check

update: ## Update flake inputs
	nix flake update

format: ## Format nix files
	nix fmt

pre-commit-install: ## Install git pre-commit hook (nix fmt + flake check + secret scan)
	@mkdir -p .git/hooks
	@cat > .git/hooks/pre-commit <<'EOF'
	#!/usr/bin/env bash
	set -euo pipefail
	echo '[pre-commit] Formatting Nix files...'
	nix fmt >/dev/null 2>&1 || true
	echo '[pre-commit] Running flake check...'
	if ! nix flake check; then
	  echo '[pre-commit] flake check failed';
	  exit 1;
	fi
	echo '[pre-commit] Scanning for plaintext secrets...'
	if grep -R --exclude-dir=secrets --exclude='*.enc' -E '(AWS_SECRET_ACCESS_KEY|AGE-SECRET-KEY|BEGIN [A-Z ]*PRIVATE KEY|oauth_token)' . >/dev/null 2>&1; then
	  echo '[pre-commit] Potential secret detected. Commit aborted.';
	  exit 1;
	fi
	echo '[pre-commit] OK'
	EOF
	@chmod +x .git/hooks/pre-commit
	@echo '✓ Pre-commit hook installed'
