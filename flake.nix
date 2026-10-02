{
  description = "NixOS fleet (x13, mouse, tank, m1)";

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
    # Deliberately NOT `inputs.nixpkgs.follows = "nixpkgs"` here: this tracks
    # a specific nixos-unstable revision tightly coupled to its Asahi kernel
    # patches/firmware, and pinning it to our nixos-26.05 risks a kernel that
    # doesn't build or doesn't match the firmware the Asahi installer laid
    # down on the machine's boot partition.
    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, lanzaboote, home-manager, nixos-apple-silicon, ... }:
    let
      # Pull fast-moving AI CLI tools straight from nixpkgs-unstable so they
      # don't lag behind the nixos-26.05 release branch. Built with
      # allowUnfree directly (rather than via `prev.config`) since some of
      # these are unfree and this pkgs instance doesn't otherwise inherit it.
      # Reads `prev.system` rather than hardcoding one so this same overlay
      # also works for the aarch64-linux m1 host.
      unstableOverlay = final: prev:
        let
          pkgsUnstable = import nixpkgs-unstable {
            inherit (prev) system;
            config.allowUnfree = true;
          };
        in
        {
          inherit (pkgsUnstable) claude-code codex antigravity-cli cursor-cli;
        };

      # Each host is `./hosts/<name>` (which imports the roles it needs) plus
      # the universal common module and home-manager wiring. `system` and
      # `extraModules` only need overriding for non-x86_64-linux hosts (m1).
      mkHost = hostname: { system ? "x86_64-linux", extraModules ? [ ] }: nixpkgs.lib.nixosSystem {
        inherit system;
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
        ] ++ extraModules;
      };
    in
    {
      nixosConfigurations = {
        x13 = mkHost "x13" { };
        mouse = mkHost "mouse" { };
        tank = mkHost "tank" { };

        # MacBook Pro (M1), bare-metal Asahi Linux. See hosts/m1/default.nix.
        m1 = mkHost "m1" {
          system = "aarch64-linux";
          extraModules = [ nixos-apple-silicon.nixosModules.default ];
        };
      };
    };
}
