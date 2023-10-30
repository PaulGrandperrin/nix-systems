# to use on Debian

# sudo apt install nix-bin nix-setup-systemd
# sudo adduser paulg nix-users # relog
# nix --extra-experimental-features "nix-command flakes" run home-manager/release-23.05 -- --extra-experimental-features "nix-command flakes" init --switch --flake github:PaulGrandperrin/nix-systems#stable-x86_64-linux-paulg
# nix --extra-experimental-features "nix-command flakes" run home-manager/master -- --extra-experimental-features "nix-command flakes" init --switch --flake github:PaulGrandperrin/nix-systems#unstable-x86_64-linux-paulg
# .nix-profile/bin/fish -l

# . .nix-profile/etc/profile.d/nix.fish
# . .nix-profile/etc/profile.d/nix.sh
# . .nix-profile/etc/profile.d/hm-session-vars.sh



{config, pkgs, inputs, ...}: {
  imports = [
    ./shared/core.nix
    #./shared/firefox.nix
    #./shared/chromium.nix
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
