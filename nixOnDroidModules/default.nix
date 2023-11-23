{pkgs, config, lib, ...}: {
  system.stateVersion = "23.11";
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

      nix.settings.auto-optimise-store = lib.mkForce false; # messes with proot hard link emulation (link2symlink): https://github.com/nix-community/nix-on-droid/issues/194
      home.packages = [
        (pkgs.writeShellScriptBin "start_sshd" ''${pkgs.openssh}/bin/sshd -f ${config.home.homeDirectory}/.sshd/config'')
      ];
    };
  };
}
