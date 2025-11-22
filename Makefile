.PHONY: help install build switch encrypt decrypt encrypt-ssh encrypt-aws encrypt-git decrypt-ssh decrypt-aws decrypt-git test clean check update format deps darwin android

# Configuration
AGE_KEY ?= $(HOME)/.config/sops/age/keys.txt
AGE_PUBKEY := age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas

# Secret directories - customize these paths
SSH_DIR ?= $(HOME)/.ssh
AWS_DIR ?= $(HOME)/.aws
GIT_SECRETS_DIR ?= ./secrets/git

# Output directory for encrypted secrets
SECRETS_OUTPUT_DIR ?= ./secrets/encrypted

# Platform detection
PLATFORM := $(shell uname -s | sed 's/Darwin/macos/' | sed 's/Linux/android/' )

help: ## Show available commands
	@echo "Dotfiles Management (Platform: $(PLATFORM))"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo ""
	@echo "Secret Directories:"
	@echo "  SSH_DIR=$(SSH_DIR)"
	@echo "  AWS_DIR=$(AWS_DIR)"
	@echo "  GIT_SECRETS_DIR=$(GIT_SECRETS_DIR)"
	@echo "  SECRETS_OUTPUT_DIR=$(SECRETS_OUTPUT_DIR)"

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
encrypt: encrypt-ssh encrypt-aws encrypt-git ## Encrypt all secret directories

encrypt-ssh: ## Encrypt SSH keys from SSH_DIR
	@echo "Encrypting SSH secrets from $(SSH_DIR)..."
	@./scripts/secrets-sync.sh -o $(SECRETS_OUTPUT_DIR) $(SSH_DIR)

encrypt-aws: ## Encrypt AWS config from AWS_DIR
	@echo "Encrypting AWS secrets from $(AWS_DIR)..."
	@./scripts/secrets-sync.sh -o $(SECRETS_OUTPUT_DIR) $(AWS_DIR)

encrypt-git: ## Encrypt git configs from GIT_SECRETS_DIR
	@echo "Encrypting Git secrets from $(GIT_SECRETS_DIR)..."
	@./scripts/secrets-sync.sh -o $(SECRETS_OUTPUT_DIR) $(GIT_SECRETS_DIR)

encrypt-custom: ## Encrypt custom directory (usage: make encrypt-custom DIR=/path/to/secrets)
	@if [ -z "$(DIR)" ]; then echo "Error: DIR not specified. Usage: make encrypt-custom DIR=/path/to/secrets"; exit 1; fi
	@echo "Encrypting secrets from $(DIR)..."
	@./scripts/secrets-sync.sh -o $(SECRETS_OUTPUT_DIR) $(DIR)

# Decryption targets
decrypt: decrypt-ssh decrypt-aws decrypt-git ## Decrypt all secrets to their destinations

decrypt-ssh: ## Decrypt SSH keys to SSH_DIR
	@echo "Decrypting SSH secrets to $(SSH_DIR)..."
	@mkdir -p $(SSH_DIR)
	@for f in $(SECRETS_OUTPUT_DIR)/ssh/*.sops.yaml; do \
		[ -f "$$f" ] || continue; \
		name=$$(basename "$$f" .sops.yaml); \
		if [ "$$name" = "passwords" ] || [ "$$name" = "tunnels" ]; then \
			echo "  Decrypting $$name..."; \
			SOPS_AGE_KEY_FILE=$(AGE_KEY) sops --decrypt "$$f" > "$(SSH_DIR)/$$name.yaml"; \
			chmod 600 "$(SSH_DIR)/$$name.yaml"; \
		else \
			echo "  Decrypting $$name..."; \
			SOPS_AGE_KEY_FILE=$(AGE_KEY) sops --decrypt --extract '["stringData"]["key"]' "$$f" > "$(SSH_DIR)/$$name"; \
			chmod 600 "$(SSH_DIR)/$$name"; \
		fi \
	done
	@echo "✓ SSH secrets decrypted"

decrypt-aws: ## Decrypt AWS config to AWS_DIR
	@echo "Decrypting AWS secrets to $(AWS_DIR)..."
	@mkdir -p $(AWS_DIR)
	@for f in $(SECRETS_OUTPUT_DIR)/aws/*.sops.yaml; do \
		[ -f "$$f" ] || continue; \
		name=$$(basename "$$f" .sops.yaml); \
		echo "  Decrypting $$name..."; \
		SOPS_AGE_KEY_FILE=$(AGE_KEY) sops --decrypt --extract '["stringData"]["key"]' "$$f" > "$(AWS_DIR)/$$name"; \
		chmod 600 "$(AWS_DIR)/$$name"; \
	done
	@echo "✓ AWS secrets decrypted"

decrypt-git: ## Decrypt git configs to GIT_SECRETS_DIR
	@echo "Decrypting Git secrets to $(GIT_SECRETS_DIR)..."
	@mkdir -p $(GIT_SECRETS_DIR)
	@for f in $(SECRETS_OUTPUT_DIR)/git/*.sops.yaml; do \
		[ -f "$$f" ] || continue; \
		name=$$(basename "$$f" .sops.yaml); \
		echo "  Decrypting $$name..."; \
		SOPS_AGE_KEY_FILE=$(AGE_KEY) sops --decrypt --extract '["stringData"]["key"]' "$$f" > "$(GIT_SECRETS_DIR)/$$name"; \
		chmod 644 "$(GIT_SECRETS_DIR)/$$name"; \
	done
	@echo "✓ Git secrets decrypted"

