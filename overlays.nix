inputs: rec {
  all-channels = final: prev: {
    stable = inputs.nixos-stable.legacyPackages.${prev.stdenv.hostPlatform.system};
    unstable = inputs.nixos-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
  };
  local-packages = (final: prev: import ./packages prev);
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
  default = inputs.nixos-stable.lib.composeManyExtensions [
    all-channels
    local-packages
    rclonefs
    devenv
    #hostapd
    my-yuzu

    inputs.nur.overlay
    inputs.rust-overlay.overlays.default
    inputs.nix-alien.overlays.default
  ];
}
