{
  description = "Nix for macOS configuration";

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {

    nixpkgs.url = "github:NixOs/nixpkgs/master";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
  };

  nixConfig = {
    substituters = [
      "https://cache.nixos.org/"
      # "https://mirror.sjtu.edu.cn/nix-channels/store?priority=10"
    ];
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nixpkgs-unstable,
      ...
    }:
    let
      # TODO replace with your own username, email, system, and hostname
      username = "nhath";
      useremail = "minhnhat97kg@gmail.com";
      system = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
      hostname = "Nathan-Macbook";
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};

      specialArgs = inputs // {
        inherit username useremail hostname;
        inherit pkgs-unstable;
        inherit inputs;
      };
    in
    {

      darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
        inherit system specialArgs;

        modules = [
          ./modules/core.nix
          ./modules/system.nix
          ./modules/host-users.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = false;
            home-manager.verbose = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${username} = import ./modules/home.nix;
          }
        ];
      };

      # nix code formatter
      formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
    };
}
