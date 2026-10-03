# hosts/nixos/rog-ally.nix
# NixOS on an ASUS ROG Ally (AMD Z1/Z2): dev box first, games second.
# Generate the hardware half on the device and commit it next to this file:
#   nixos-generate-config --show-hardware-config > hosts/nixos/rog-ally-hardware.nix
{ pkgs, lib, ... }:
{
  imports = [ ./rog-ally-hardware.nix ];

  networking.hostName = "rog-ally";
  time.timeZone = "Asia/Ho_Chi_Minh";
  system.stateVersion = "26.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Handheld support (asus-wmi, controller, audio) lands in new kernels first.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableRedistributableFirmware = true;

  # Handheld Daemon: controller/gyro, TDP, charge limit, all from its UI.
  # Its adjustor runs its own power-profiles-daemon D-Bus server, so the real
  # PPD (and TLP/tuned) must stay off or they fight over TDP.
  services.handheld-daemon = {
    enable = true;
    adjustor.enable = true; # TDP control; off by default in the module
    user = "nhathuynh";
  };
  services.power-profiles-daemon.enable = lib.mkForce false;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Desktop: niri session; the user config comes from home-manager
  # (modules/home/niri.nix). This adds the session file, portals and polkit.
  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
  };

  programs.zsh.enable = true;
  # Rootless podman needs the setuid newuidmap and /etc/containers policy that
  # only the system module provides; modules/home/podman.nix adds the socket.
  virtualisation.podman.enable = true;
  programs.steam.enable = true;

  users.users.nhathuynh = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "nhathuynh" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nixpkgs.config.allowUnfree = true; # steam

  home-manager.users.nhathuynh = {
    imports = [
      ../../modules/home/default.nix
      ../../modules/home/linux-desktop.nix
    ];
    home.username = "nhathuynh";
    home.homeDirectory = "/home/nhathuynh";
    manual.manpages.enable = false; # same options.json warning as modules/platforms/linux.nix
  };
}
