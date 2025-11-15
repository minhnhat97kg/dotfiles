.PHONY: help install build switch decrypt-all decrypt-aws decrypt-ssh encrypt-aws encrypt-ssh test-decrypt clean

# Configuration
AGE_KEY := ~/.config/sops/age/keys.txt
AGE_PUBKEY := age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas
DOTFILES := $(shell pwd)

help: ## Show this help message
	@echo "Dotfiles Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install nix-darwin configuration
	@echo "Installing nix-darwin configuration..."
	darwin-rebuild switch --flake .

build: ## Build nix-darwin configuration (without activation)
	@echo "Building nix-darwin configuration..."
	darwin-rebuild build --flake .

switch: decrypt-all ## Decrypt secrets and switch configuration
	@echo "Switching nix-darwin configuration..."
	darwin-rebuild switch --flake .

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
