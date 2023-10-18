{pkgs, config, ...}: {
  system.stateVersion = "23.05";
  user.shell = "${pkgs.fish}/bin/fish";
  terminal.font = "${pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; }}/share/fonts/truetype/NerdFonts/FiraCodeNerdFont-Retina.ttf";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = config._module.specialArgs;
    config = {config, lib, ...}: {
      imports = [
        ../homeModules/shared/core.nix
      ];

      home.packages = [
        (pkgs.writeShellScriptBin "start_sshd" ''${pkgs.openssh}/bin/sshd -f ${config.home.homeDirectory}/.sshd/config'')
      ];
    };
  };
}
