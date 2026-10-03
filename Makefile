.PHONY: help install build update format check clean darwin android nix-on-droid linux termux apt-deps qutebrowser-venv sf-fonts

# Detect platform: macos, termux, android, ubuntu
_UNAME := $(shell uname -s)
_IS_TERMUX := $(shell [ -d /data/data/com.termux ] || [ -n "$$TERMUX_VERSION" ] && echo yes || echo no)
_IS_DROID := $(shell command -v nix-on-droid > /dev/null 2>&1 && echo yes || echo no)

ifeq ($(_UNAME),Darwin)
  PLATFORM := macos
else ifeq ($(_IS_DROID),yes)
  PLATFORM := android
else ifeq ($(_IS_TERMUX),yes)
  PLATFORM := termux
else
  PLATFORM := ubuntu
endif

help: ## Show available commands
	@echo "Dotfiles Management (Platform: $(PLATFORM))"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# First run on a Mac has no darwin-rebuild yet — fetch it from the flake input.
DARWIN_REBUILD := $(shell command -v darwin-rebuild 2>/dev/null || echo "nix --extra-experimental-features 'nix-command flakes' run --inputs-from . nix-darwin\#darwin-rebuild --")

install: ## Install configuration (auto-detect platform)
ifeq ($(PLATFORM),macos)
	sudo $(DARWIN_REBUILD) switch --flake .
else ifeq ($(PLATFORM),android)
	nix-on-droid switch --flake .
else
	nix run --inputs-from . home-manager -- switch --flake .#$(PLATFORM)
endif

darwin: ## Install on macOS (nix-darwin)
	sudo $(DARWIN_REBUILD) switch --flake .

nix-on-droid: ## Install on Android (nix-on-droid)
	nix-on-droid switch --flake .

android: nix-on-droid ## Alias for nix-on-droid

linux: ## Install on Ubuntu Linux
	nix run --inputs-from . home-manager -- switch --flake .#ubuntu

apt-deps: ## Install apt packages the ubuntu host needs but Nix can't provide (kitty, fcitx5)
	./hosts/linux/ubuntu-apt-deps.sh

qutebrowser-venv: ## Install qutebrowser into a pip venv (Nix build crashes on EGL init)
	./hosts/linux/ubuntu-qutebrowser-venv.sh

sf-fonts: ## Install Apple SF Pro/SF Mono (not redistributable, so not in Nix)
	./hosts/linux/ubuntu-sf-fonts.sh

termux: ## Install on Termux (aarch64)
	nix run --inputs-from . home-manager -- switch --flake .#termux

update: ## Update flake inputs
	nix flake update

format: ## Format nix files
	nix fmt

check: ## Validate flake
	nix flake check

clean: ## Remove build artifacts
	rm -f result result-*
