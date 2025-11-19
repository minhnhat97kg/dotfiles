.PHONY: help install build switch encrypt decrypt encrypt-ssh encrypt-aws encrypt-git decrypt-ssh decrypt-aws decrypt-git test clean check update format deps darwin android

# Configuration
AGE_KEY ?= ~/.config/sops/age/keys.txt
AGE_PUBKEY := age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas

# Secret directories - customize these paths
SSH_DIR ?= ~/.ssh
AWS_DIR ?= ~/.aws
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
else
	nix-on-droid switch --flake .
endif

darwin: ## Install on macOS (nix-darwin)
	darwin-rebuild switch --flake .

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
		echo "  Decrypting $$name..."; \
		SOPS_AGE_KEY_FILE=$(AGE_KEY) sops --decrypt --extract '["stringData"]["key"]' "$$f" > "$(SSH_DIR)/$$name"; \
		chmod 600 "$(SSH_DIR)/$$name"; \
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

decrypt-custom: ## Decrypt custom secrets (usage: make decrypt-custom SRC=ssh DEST=~/.ssh)
	@if [ -z "$(SRC)" ] || [ -z "$(DEST)" ]; then echo "Error: SRC and DEST required. Usage: make decrypt-custom SRC=ssh DEST=~/.ssh"; exit 1; fi
	@echo "Decrypting $(SRC) secrets to $(DEST)..."
	@mkdir -p $(DEST)
	@for f in $(SECRETS_OUTPUT_DIR)/$(SRC)/*.sops.yaml; do \
		[ -f "$$f" ] || continue; \
		name=$$(basename "$$f" .sops.yaml); \
		echo "  Decrypting $$name..."; \
		SOPS_AGE_KEY_FILE=$(AGE_KEY) sops --decrypt --extract '["stringData"]["key"]' "$$f" > "$(DEST)/$$name"; \
		chmod 600 "$(DEST)/$$name"; \
	done
	@echo "✓ Secrets decrypted"

list-secrets: ## List all encrypted secrets
	@echo "Encrypted secrets in $(SECRETS_OUTPUT_DIR):"
	@find $(SECRETS_OUTPUT_DIR) -name "*.sops.yaml" -type f 2>/dev/null | sort | sed 's|^|  |' || echo "  (none found)"

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

test-decrypt: ## Test decryption to /tmp
	@rm -rf /tmp/dotfiles-decrypt-test
	@mkdir -p /tmp/dotfiles-decrypt-test/ssh
	@echo "Testing decryption..."
	@for f in $(SECRETS_OUTPUT_DIR)/ssh/*.sops.yaml; do \
		[ -f "$$f" ] || continue; \
		name=$$(basename "$$f" .sops.yaml); \
		SOPS_AGE_KEY_FILE=$(AGE_KEY) sops --decrypt --extract '["stringData"]["key"]' "$$f" > "/tmp/dotfiles-decrypt-test/ssh/$$name"; \
	done
	@echo "✓ Test complete: /tmp/dotfiles-decrypt-test"

clean: ## Clean build artifacts
	@rm -rf result result-* /tmp/dotfiles-test /tmp/dotfiles-decrypt-test

gen-key: ## Generate or import age key
	@echo "Choose an option:"
	@echo "  1) Generate new age key"
	@echo "  2) Import existing age key"
	@read -p "Enter choice [1/2]: " choice; \
	mkdir -p ~/.config/sops/age; \
	if [ "$$choice" = "1" ]; then \
		age-keygen -o ~/.config/sops/age/keys.txt; \
		echo ""; \
		echo "⚠️  Update AGE_PUBKEY in Makefile with the public key shown above!"; \
	elif [ "$$choice" = "2" ]; then \
		echo "Paste your age private key (AGE-SECRET-KEY-...):"; \
		read -r age_key; \
		echo "$$age_key" > ~/.config/sops/age/keys.txt; \
		chmod 600 ~/.config/sops/age/keys.txt; \
		echo "✓ Age key saved"; \
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
