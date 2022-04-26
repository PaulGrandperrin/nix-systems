{pkgs, inputs, ...}: {

  imports = [
    ./nix-registry.nix
  ];

  nix.package = pkgs.nix_2_4;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
    auto-optimise-store = true
  '';

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 2d";
    interval = {
      Hour = 5;
      Minute = 0;
    };
  };

  system.defaults.NSGlobalDomain = {
    InitialKeyRepeat = 33; # unit is 15ms, so 500ms
    KeyRepeat = 2; # unit is 15ms, so 30ms
    NSDocumentSaveNewDocumentsToCloud = false;
  };


  services.nix-daemon.enable = true;
  environment.systemPackages = [];

  system.stateVersion = 4;

  programs = {
    fish.enable = true;
  };

  environment.shells = [pkgs.fish];

  homebrew = {
    enable = true;
    #cleanup = "zap";
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
      "android-platform-tools"
      "android-file-transfer"
    ];
    masApps = {};
  };

  fonts = {
    fontDir.enable = true;
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
