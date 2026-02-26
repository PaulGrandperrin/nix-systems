inputs: rec {
  all-channels = final: prev: {
    stable = import inputs.nixos-stable {
      system = prev.stdenv.hostPlatform.system;
      #overlays = [ ];
      config = import ./nixpkgs/config.nix;
    };
    unstable = import inputs.nixos-unstable {
      system = prev.stdenv.hostPlatform.system;
      #overlays = [ ];
      config = import ./nixpkgs/config.nix;
    };
  };
  local-packages = (final: prev: import ./packages {pkgs = final; inherit inputs;});
  nixpkgs-update = (final: prev: inputs.nixpkgs-update.packages.${prev.stdenv.hostPlatform.system} or {});
  rclonefs = (final: prev: {
    rclone = (prev.symlinkJoin { # create filesystem helpers until https://github.com/NixOS/nixpkgs/issues/258478
      name = "rclone";
      paths = [ prev.rclone ];
      postBuild = ''
        ln -sf $out/bin/rclone $out/bin/mount.rclone 
        ln -sf $out/bin/rclone $out/bin/rclonefs
      '';
    });
  });
  devenv = (final: prev: {
    devenv = inputs.devenv.packages.${prev.stdenv.hostPlatform.system}.devenv;
  });
  isd = (final: prev: {
    isd = inputs.isd.packages.${prev.stdenv.hostPlatform.system}.isd;
  });
  hostapd = (final: prev: {
    hostapd = prev.hostapd.overrideAttrs (oldAttrs: {
      #patches = oldAttrs.patches ++ [
      patches = [
        (prev.fetchpatch { # hack to work with intel LAR
          url = "https://raw.githubusercontent.com/openwrt/openwrt/eefed841b05c3cd4c65a78b50ce0934d879e6acf/package/network/services/hostapd/patches/300-noscan.patch";
          hash = "sha256-q9yWc5FYhzUFXNzkVIgNe6gxJyE1hQ/iShEluVroiTE=";
          #url = "https://tildearrow.org/storage/hostapd-2.10-lar.patch";
          #hash = "sha256-USiHBZH5QcUJfZSxGoFwUefq3ARc4S/KliwUm8SqvoI=";
          #url = "https://github.com/coolsnowwolf/lede/files/9388276/999-hostapd-2.10-lar.patch.txt";
          #hash = "sha256-V/dPSjkcCNmj3HK85LD1PFVRgod7U4nh15sKbobfx5A=";
        })
      ];
    });
  });
  my-yuzu = (final: prev: {
    #my-yuzu = (prev.callPackage (final.unstable.path + "/pkgs/applications/emulators/yuzu") {}).mainline.overrideAttrs (_: {
    #  meta.platforms = prev.lib.platforms.linux;
    #});
    my-yuzu = final.unstable.yuzuPackages.mainline.overrideAttrs (_: {
      meta.platforms = prev.lib.platforms.linux;
    });
  });
  #fish-unstable = (final: prev: {
  #  fish = final.unstable.fish;
  #});
  cosmic-unstable = (final: prev: {
    cosmic-applets = prev.unstable.cosmic-applets;
    cosmic-applibrary = prev.unstable.cosmic-applibrary;
    cosmic-bg = prev.unstable.cosmic-bg;
    cosmic-comp = prev.unstable.cosmic-comp;
    cosmic-edit = prev.unstable.cosmic-edit;
    cosmic-files = prev.unstable.cosmic-files;
    cosmic-greeter = prev.unstable.cosmic-greeter;
    cosmic-icons = prev.unstable.cosmic-icons;
    cosmic-idle = prev.unstable.cosmic-idle;
    cosmic-initial-setup = prev.unstable.cosmic-initial-setup;
    cosmic-launcher = prev.unstable.cosmic-launcher;
    cosmic-notifications = prev.unstable.cosmic-notifications;
    cosmic-osd = prev.unstable.cosmic-osd;
    cosmic-panel = prev.unstable.cosmic-panel;
    cosmic-player = prev.unstable.cosmic-player;
    cosmic-randr = prev.unstable.cosmic-randr;
    cosmic-screenshot = prev.unstable.cosmic-screenshot;
    cosmic-session = prev.unstable.cosmic-session;
    cosmic-settings-daemon = prev.unstable.cosmic-settings-daemon;
    cosmic-settings = prev.unstable.cosmic-settings;
    cosmic-store = prev.unstable.cosmic-store;
    cosmic-term = prev.unstable.cosmic-term;
    cosmic-wallpapers = prev.unstable.cosmic-wallpapers;
    cosmic-workspaces-epoch = prev.unstable.cosmic-workspaces-epoch;
    xdg-desktop-portal-cosmic = prev.unstable.xdg-desktop-portal-cosmic;
    system76-power = prev.unstable.system76-power;

    cosmic-ext-applet-caffeine = prev.unstable.cosmic-ext-applet-caffeine;
    cosmic-ext-applet-external-monitor-brightness = prev.unstable.cosmic-ext-applet-external-monitor-brightness;
    cosmic-ext-applet-minimon = prev.unstable.cosmic-ext-applet-minimon;
    cosmic-ext-applet-privacy-indicator = prev.unstable.cosmic-ext-applet-privacy-indicator;
    cosmic-ext-calculator = prev.unstable.cosmic-ext-calculator;
    cosmic-ext-ctl = prev.unstable.cosmic-ext-ctl;
    cosmic-ext-tweaks = prev.unstable.cosmic-ext-tweaks;
    cosmic-protocols = prev.unstable.cosmic-protocols;
    cosmic-reader = prev.unstable.cosmic-reader;
    examine = prev.unstable.examine;
  });
  default = inputs.nixos-stable.lib.composeManyExtensions [
    all-channels
    local-packages
    rclonefs
    nixpkgs-update
    devenv
    isd
    #hostapd
    my-yuzu
    #fish-unstable
    cosmic-unstable

    inputs.nur.overlays.default
    inputs.rust-overlay.overlays.default
    inputs.nix-alien.overlays.default
    #inputs.lix.overlays.default
  ];
}
