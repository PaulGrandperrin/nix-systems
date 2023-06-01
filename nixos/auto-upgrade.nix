{
  system.autoUpgrade = {
    enable = true;
    flake = "git+ssh://git@github.com/PaulGrandperrin/nix-systems?ref=main";
    #flake = "git+file:///etc/nixos/";
    #flags = [ "--update-input" "nixos" "--commit-lock-file" ];
    flags = [ "--update-input" "nixos-23-05" "--update-input" "nixos-23-05-small" "--update-input" "nur" "--update-input" "flake-utils" "--no-write-lock-file" ];
    dates = "04:00:00";
    allowReboot = true;
    rebootWindow = {
      lower = "02:00";
      upper = "03:00";
    };
  };

}
