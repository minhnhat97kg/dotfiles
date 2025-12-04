{ config, pkgs, lib, username, useremail, ... }:

{
  # Boot and hardware configuration
  # Note: These should be customized based on your hardware
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Filesystem configuration
  # IMPORTANT: You must customize this for your hardware
  # Generate with: sudo nixos-generate-config --show-hardware-config
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Networking
  networking.networkmanager.enable = true;

  # Time zone and locale
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # User configuration
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # Enable unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages (shared packages will be added via home-manager)
  environment.systemPackages = with pkgs; [
    # Terminal & shell
    alacritty
    zsh

    # System utilities
    vim
    wget
    curl
    htop

    # Nix tools
    home-manager
  ];

  # Programs
  programs.zsh.enable = true;
  programs.git.enable = true;

  # Enable Docker (optional, commented out by default)
  # virtualisation.docker.enable = true;

  # Enable sound with PipeWire (modern alternative to PulseAudio)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # X11 / Wayland display server
  services.xserver = {
    enable = lib.mkDefault true;
    xkb.layout = lib.mkDefault "us";
  };

  # Desktop Environment (choose one)
  # GNOME
  services.displayManager.gdm.enable = lib.mkDefault true;
  services.desktopManager.gnome.enable = lib.mkDefault true;

  # KDE Plasma (alternative)
  # services.displayManager.sddm.enable = lib.mkDefault true;
  # services.desktopManager.plasma6.enable = lib.mkDefault true;

  # i3 (tiling window manager alternative)
  # services.xserver.windowManager.i3.enable = lib.mkDefault true;

  # Enable touchpad support (for laptops)
  # services.xserver.libinput.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # System state version
  system.stateVersion = "24.05";
}
