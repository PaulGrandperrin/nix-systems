{
  system.autoUpgrade.enable = true;
  #system.autoUpgrade.flake = "git+ssh://git@github.com/PaulGrandperrin/nixos-conf?ref=main";
  system.autoUpgrade.flake = "git+file:///etc/nixos/";
  #system.autoUpgrade.flags = [ "--update-input" "nixos" "--commit-lock-file" ];
  system.autoUpgrade.flags = [ "--update-input" "nixos" "--update-input" "flake-utils" "--no-write-lock-file" ];
  system.autoUpgrade.allowReboot = true;
}
