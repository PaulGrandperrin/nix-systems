inputs: let 
  mkHomeConf = stability: system: username: module: let 
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability};
    nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
  in
    home-manager-flake.lib.homeManagerConfiguration {
      pkgs = nixos-flake.legacyPackages.${system};
      extraSpecialArgs = {inherit inputs nixos-flake home-manager-flake;};
      modules = [ 
        {
          home = {
            inherit username;
          };
        }
        ./homeModules/standalone.nix
      ];
    };
in {
  unstable-x86_64-linux-paulg = mkHomeConf "unstable" "x86_64-linux" "paulg" ./homeModules/standalone.nix;
}
