{pkgs, ...}: {
  nix.package = pkgs.nix_2_4;
  nix.extraOptions = "experimental-features = nix-command flakes";

  services.nix-daemon.enable = true;
  environment.systemPackages = [];

  system.stateVersion = 4;

  programs = {
    fish.enable = true;
  };

  environment.shells = [pkgs.fish];

  homebrew = {
    enable = true;
    cleanup = "zap";
    global = {
      brewfile = true;
      noLock = true;
    };
    taps = ["homebrew/bundle" "homebrew/cask" "homebrew/core"];
    brews = [];
    casks = [
      "iterm2"
      "firefox"
      "messenger"
      "discord"
      "google-drive"
      "messenger"
      "protonvpn"
      "signal"
      "telegram"
      "tor-browser"
      "transmission"
      "twitch"
      "visual-studio-code"
      "vlc"
      "whatsapp"
    ];
    masApps = {};
  };

  fonts = {
    enableFontDir = true;
    fonts = [
      ( pkgs.nerdfonts.override {
        fonts = [
          "CascadiaCode"
          "FantasqueSansMono"
          "FiraCode"
          "FiraMono"
          "Hack" # no ligatures
          "Hasklig"
          "Inconsolata"
          "Iosevka"
          "JetBrainsMono"
          "VictorMono"
        ];
      } )
    ];
  };
}
