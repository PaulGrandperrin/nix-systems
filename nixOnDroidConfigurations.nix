inputs: let
  mkDroidConf = stability: system: module: let
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
    nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
  in
    inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import nixos-flake {
        inherit system;
        overlays = [
          (import ./overlays.nix inputs).default
          inputs.nix-on-droid.overlays.default
        ];
        config = import ./nixpkgs/config.nix;
      };
      extraSpecialArgs = { inherit inputs nixos-flake home-manager-flake;};
      home-manager-path = home-manager-flake;

      modules = [ module ];
    };
in {
  default = mkDroidConf "stable" "aarch64-linux" ./nixOnDroidModules/default.nix;
}

