inputs: let
  mkDarwinConf = stability: arch: let
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
    nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
  in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs nixos-flake home-manager-flake;}; #  passes inputs and main flakes to modules
      modules = [
        ({lib, ...}: {
          nixpkgs.hostPlatform = lib.mkDefault "${arch}-darwin";
        })
        ./darwinModules/common.nix
      ];
    };
in {
  "MacBookPaul" = mkDarwinConf "stable" "x86_64";
  "MacMiniPaul" = mkDarwinConf "stable" "x86_64";
}
# inputs-patched = inputs // {nixpkgs = inputs.darwin-23-05; darwin = inputs.nix-darwin;};
