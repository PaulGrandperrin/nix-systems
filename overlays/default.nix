inputs: let # FIXME not sure those are the good channels for darwin
  all-pkgs-overlay = final: prev: {
    stable = inputs.nixos-23-05.legacyPackages.${prev.stdenv.hostPlatform.system};
    unstable = inputs.nixos-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
  };
in [
  all-pkgs-overlay
  inputs.nur.overlay
  inputs.rust-overlay.overlays.default
  inputs.nix-alien.overlays.default
  (final: prev: {
    rclone = (prev.symlinkJoin { # create filesystem helpers until https://github.com/NixOS/nixpkgs/issues/258478
      name = "rclone";
      paths = [ prev.rclone ];
      postBuild = ''
        ln -sf $out/bin/rclone $out/bin/mount.rclone 
        ln -sf $out/bin/rclone $out/bin/rclonefs
      '';
    });
  })
]
