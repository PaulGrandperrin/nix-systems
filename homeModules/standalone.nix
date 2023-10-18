{config, pkgs, inputs, ...}: {
  imports = [
    ./shared/core.nix
    #./shared/firefox.nix
    #./shared/chromium.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (import ../overlays.nix inputs).default
    ];
  };

  home = {
    # mandatory when HM is used as a standalone
    homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then # we assume that the username is set elsewhere
      if (config.home.username == "root") then "/var/root" else "/Users/${config.home.username}"
     else 
      if (config.home.username == "root") then "/root" else "/home/${config.home.username}"
    ;
  };
}
