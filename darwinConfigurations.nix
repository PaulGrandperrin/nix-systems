inputs: let
  mkDarwinConf = stability: module: let
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
    nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
  in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs nixos-flake home-manager-flake;}; # passes inputs and main flakes to modules
      modules = [ module ];
    };
in {
  "MacBookPaul" = mkDarwinConf "stable" ./darwinModules/MacBookPaul.nix;
  "MacMiniPaul" = mkDarwinConf "stable" ./darwinModules/MacMiniPaul.nix;
}
