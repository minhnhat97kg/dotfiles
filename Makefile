.PHONY: help install build switch update format check clean darwin android linux wsl termux

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

install: ## Install configuration (auto-detect platform)
ifeq ($(PLATFORM),macos)
	sudo darwin-rebuild switch --flake .
	@echo ""
else ifeq ($(PLATFORM),android)
	nix-on-droid switch --flake .
else
	home-manager switch --flake .#$(PLATFORM)
endif

darwin: ## Install on macOS (nix-darwin)
	sudo darwin-rebuild switch --flake .
	@echo ""

android: ## Install on Android (nix-on-droid)
	nix-on-droid switch --flake .

linux: ## Install on Ubuntu Linux (home-manager)
	home-manager switch --flake .#ubuntu

wsl: ## Install on WSL (home-manager)
	home-manager switch --flake .#wsl

termux: ## Install on Termux (home-manager, aarch64)
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
