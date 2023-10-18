inputs: let
  mkDroidConf = stability: system: let
    selectFlake = stable: unstable: { inherit stable unstable; }.${stability}; 
    nixos-flake = selectFlake inputs.nixos-23-05 inputs.nixos-unstable;
    home-manager-flake = selectFlake inputs.home-manager-23-05 inputs.home-manager-master;
  in
    inputs.nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import nixos-flake {
        inherit system;
        overlays = (import ./overlays inputs) ++ [ inputs.nix-on-droid.overlays.default ];
        config.allowUnfree = true;
      };
      extraSpecialArgs = { inherit inputs nixos-flake home-manager-flake;};
      home-manager-path = home-manager-flake;

      modules = [
        ({pkgs, config, ...}: {
          system.stateVersion = "23.05";
          user.shell = "${pkgs.fish}/bin/fish";
          terminal.font = "${pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; }}/share/fonts/truetype/NerdFonts/Fira Code Regular Nerd Font Complete Mono.ttf";

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = config._module.specialArgs;
            config = {config, lib, ...}: {
              imports = [
                ./homeModules/shared/core.nix
              ];

              home.packages = [
                (pkgs.writeShellScriptBin "start_sshd" ''${pkgs.openssh}/bin/sshd -f ${config.home.homeDirectory}/sshd/config'')
              ];
            };
          };
        })
      ];
    };
in {
  default = mkDroidConf "stable" "aarch64-linux";
}
  
