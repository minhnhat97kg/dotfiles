.PHONY: help darwin android update fmt check clean

# Default target
help:
	@echo "Available targets:"
	@echo "  make darwin   - Apply macOS configuration"
	@echo "  make android  - Apply Android configuration"
	@echo "  make update   - Update all flake inputs"
	@echo "  make fmt      - Format Nix files"
	@echo "  make check    - Check flake validity"
	@echo "  make clean    - Run garbage collection"

# macOS configuration
darwin:
	sudo darwin-rebuild switch --flake .

# Android configuration (nix-on-droid)
android:
	nix-on-droid switch --flake .

# Update flake inputs
update:
	nix flake update

# Format Nix code
fmt:
	nix fmt

# Check flake validity
check:
	nix flake check

# Garbage collection
clean:
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		echo "Running macOS garbage collection..."; \
		nix-collect-garbage -d; \
	elif command -v nix-on-droid >/dev/null 2>&1; then \
		echo "Running Android garbage collection..."; \
		nix-on-droid on-device nix-collect-garbage -d; \
	else \
		echo "No Nix Darwin or Nix-on-Droid detected"; \
	fi

# Default when just running 'make'
default: help
