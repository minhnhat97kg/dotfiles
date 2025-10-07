default: init
init: flake.nix
	darwin-rebuild switch --flake .
