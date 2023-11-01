{config, pkgs, inputs, ...}: {
  imports = [
    ./shared/core.nix
  ];

  nixpkgs = {
    config = import ../nixpkgs/config.nix;
    overlays = [
      (import ../overlays.nix inputs).default
    ];
  };

  programs.home-manager.enable = true;

  home = {
    # mandatory when HM is used as a standalone
    homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then # we assume that the username is set elsewhere
      if (config.home.username == "root") then "/var/root" else "/Users/${config.home.username}"
     else 
      if (config.home.username == "root") then "/root" else "/home/${config.home.username}"
    ;
  };
}
