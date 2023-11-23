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
  default = inputs.nixos-stable.lib.composeManyExtensions [
    all-channels
    local-packages
    rclonefs
    devenv

    inputs.nur.overlay
    inputs.rust-overlay.overlays.default
    inputs.nix-alien.overlays.default
  ];
}
