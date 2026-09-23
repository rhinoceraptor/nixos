{
  description = "NixOS fleet (x13, mouse, tank)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, lanzaboote, home-manager, ... }:
    let
      # Pull fast-moving AI CLI tools straight from nixpkgs-unstable so they
      # don't lag behind the nixos-26.05 release branch. Built with
      # allowUnfree directly (rather than via `prev.config`) since some of
      # these are unfree and this pkgs instance doesn't otherwise inherit it.
      pkgsUnstable = import nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      unstableOverlay = final: prev: {
        inherit (pkgsUnstable) claude-code codex antigravity-cli cursor-cli;
      };

      # Each host is `./hosts/<name>` (which imports the roles it needs) plus
      # the universal common module and home-manager wiring.
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = [ unstableOverlay ]; }
          ./modules/common.nix
          ./hosts/${hostname}
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        x13 = mkHost "x13";
        mouse = mkHost "mouse";
        tank = mkHost "tank";
      };
    };
}
