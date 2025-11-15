.PHONY: help install build switch decrypt encrypt test clean check update format

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

# Main targets
install: decrypt ## Decrypt and install configuration
ifeq ($(PLATFORM),macos)
	darwin-rebuild switch --flake .
else
	nix-on-droid switch --flake .
endif

build: ## Build configuration without installing
ifeq ($(PLATFORM),macos)
	darwin-rebuild build --flake .
else
	nix-on-droid build --flake .
endif

switch: decrypt install ## Decrypt secrets and switch configuration

decrypt: ## Decrypt all secrets (use AGE_KEY=/path to override)
	@if [ ! -f "$(AGE_KEY)" ]; then \
		echo "❌ Age key not found at: $(AGE_KEY)"; \
		echo "   Generate one with: make gen-key"; \
		echo "   Or specify: make decrypt AGE_KEY=/path/to/key.txt"; \
		exit 1; \
	fi
	@./scripts/decrypt-secrets.sh

encrypt: ## Encrypt all secrets (use AGE_KEY=/path to override)
	@if [ ! -f "$(AGE_KEY)" ]; then \
		echo "❌ Age key not found at: $(AGE_KEY)"; \
		exit 1; \
	fi
	@./scripts/encrypt-secrets.sh

test: ## Test decryption in /tmp
	@rm -rf /tmp/dotfiles-test
	@mkdir -p /tmp/dotfiles-test/.config/sops/age
	@cp $(AGE_KEY) /tmp/dotfiles-test/.config/sops/age/
	@HOME=/tmp/dotfiles-test ./scripts/decrypt-secrets.sh
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
