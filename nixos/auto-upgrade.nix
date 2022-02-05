{
  system.autoUpgrade = {
    enable = true;
    #flake = "git+ssh://git@github.com/PaulGrandperrin/nixos-conf?ref=main";
    flake = "git+file:///etc/nixos/";
    #flags = [ "--update-input" "nixos" "--commit-lock-file" ];
    flags = [ "--update-input" "nixos" "--update-input" "flake-utils" "--no-write-lock-file" ];
    dates = "04:00:00";
    allowReboot = true;
  };

}
