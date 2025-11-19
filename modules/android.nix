{ pkgs, ... }:
{
  system.stateVersion = "24.05";
  nix.extraOptions = "experimental-features = nix-command flakes";
  nix.substituters = [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
  nix.trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
  user.shell = pkgs.zsh;
  environment.packages = with pkgs; [ git fzf procps gnugrep gnused gawk coreutils go gcc gnumake zsh oh-my-zsh openssh net-tools mosh tailscale ];
}
