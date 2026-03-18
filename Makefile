.PHONY: help install build update format check clean darwin android linux wsl termux

# Detect platform: macos, wsl, termux, android, linux
_UNAME := $(shell uname -s)
_IS_WSL := $(shell grep -qi microsoft /proc/version 2>/dev/null && echo yes || echo no)
_IS_TERMUX := $(shell [ -d /data/data/com.termux ] || [ -n "$$TERMUX_VERSION" ] && echo yes || echo no)
_IS_DROID := $(shell command -v nix-on-droid > /dev/null 2>&1 && echo yes || echo no)

ifeq ($(_UNAME),Darwin)
  PLATFORM := macos
else ifeq ($(_IS_DROID),yes)
  PLATFORM := android
else ifeq ($(_IS_WSL),yes)
  PLATFORM := wsl
else ifeq ($(_IS_TERMUX),yes)
  PLATFORM := termux
else
  PLATFORM := linux
endif

help: ## Show available commands
	@echo "Dotfiles Management (Platform: $(PLATFORM))"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install configuration (auto-detect platform)
ifeq ($(PLATFORM),macos)
	sudo darwin-rebuild switch --flake .
else ifeq ($(PLATFORM),android)
	nix-on-droid switch --flake .
else
	nix run 'github:nix-community/home-manager' -- switch --flake .#$(PLATFORM)
endif

darwin: ## Install on macOS (nix-darwin)
	sudo darwin-rebuild switch --flake .

android: ## Install on Android (nix-on-droid)
	nix-on-droid switch --flake .

linux: ## Install on Ubuntu Linux
	nix run 'github:nix-community/home-manager' -- switch --flake .#ubuntu

wsl: ## Install on WSL
	nix run 'github:nix-community/home-manager' -- switch --flake .#wsl

termux: ## Install on Termux (aarch64)
	nix run 'github:nix-community/home-manager' -- switch --flake .#termux

update: ## Update flake inputs
	nix flake update

format: ## Format nix files
	nix fmt

check: ## Validate flake
	nix flake check

clean: ## Remove build artifacts
	rm -f result result-*
