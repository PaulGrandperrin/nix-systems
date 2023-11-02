inputs: rec {
  all-channels = final: prev: {
    stable = inputs.nixos-23-05.legacyPackages.${prev.stdenv.hostPlatform.system};
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
  default = inputs.nixos-23-05-lib.lib.composeManyExtensions [
    all-channels
    local-packages
    rclonefs

    inputs.nur.overlay
    inputs.rust-overlay.overlays.default
    inputs.nix-alien.overlays.default
  ];
}
