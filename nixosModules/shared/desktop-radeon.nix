{ config, pkgs, lib, modulesPath, ... }:
{
  # no need to set services.xserver.videoDrivers because I don't use Xorg but only XWayland which don't use it. and anyway, the default "modesetting" is good.

  environment.systemPackages = with pkgs; [
    amdgpu_top 
    nvtopPackages.amd
    rocmPackages.rocm-smi
    unstable.amd-debug-tools
  ];

  # https://wiki.nixos.org/wiki/AMD_GPU#HIP
  systemd.tmpfiles.rules = 
  let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [
        rocblas
        hipblas
        clr
      ];
    };
  in [
    "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
  ];

  hardware.amdgpu = {
    initrd.enable = true;
    opencl.enable = true; # adds rocmPackages.clr(.icd) to hardware.graphics.extraPackages
    #overdrive = {
    #  enable = true;
    #  ppfeaturemask = "0xffffffff"; # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/drivers/gpu/drm/amd/include/amd_shared.h#n169
    #};
  };


  nixpkgs.overlays = [(final: prev: {
    linux-firmware = final.unstable.linux-firmware;
    #linux-firmware = (final.unstable.linux-firmware.overrideAttrs (finalAttrs: prevAttrs: {
    #  version = "git";
    #  src = prev.fetchFromGitLab {
    #    owner = "kernel-firmware";
    #    repo = "linux-firmware";
    #    rev = "e272e0d1edce58496c3917f7422b9531daeb0535";
    #    hash = "sha256-idXFIaw5mSeQe4x+HkNYhOIzQ+R5Bfab7Urer7a/vUs=";
    #  };
    #}));
  })];

  services.lact.enable = true;

  #programs.ryzen-monitor-ng.enable = true; # breaks suspend, unofficial, not recommended by AMD

  # suspend-then-hibernate bug: https://gitlab.freedesktop.org/drm/amd/-/issues/4866

  #boot.kernelPatches = [{
  #  name = "amdgpu suspend fix";
  #  patch = (pkgs.fetchurl {
  #    url = "https://lore.kernel.org/amd-gfx/20251130014631.29755-1-superm1@kernel.org/t.mbox.gz";
  #    hash = "sha256-HhJn8BZKVK0dYpX48z3gnPSYrw3dIEbkuH6h21Fzkp4=";
  #  });
  #}];

  #boot.extraModulePackages = let # FIXME can cause issues with dm_crypt, only in the initrd, WTF
  #  # https://gist.github.com/al3xtjames/a9aff722b7ddf8c79d6ce4ca85c11eaa
  #  decodeMbox = pkgs.writeShellScript "decodeMbox" ''
  #    # The lore.kernel.org mailing list uses public-inbox, which supports
  #    # downloading threads as a gzip-compressed mbox file (see the "mbox.gz" link
  #    # next to "Thread overview"). This can be used to download a patch series in
  #    # a single file. However, public-inbox may not sort the messages in the
  #    # thread [1], which may break application of the patches. b4 am [2] can be
  #    # used to sort patches in the mbox file and produce a patch that can be
  #    # applied with git am or patch.
  #    # [1]: https://public-inbox.org/meta/20240411-dancing-pink-marmoset-f442d0@meerkat/
  #    # [2]: https://b4.docs.kernel.org/en/latest/maintainer/am-shazam.html
  #    # b4 expects git to be in $PATH and $XDG_DATA_HOME to be writable.
  #    export PATH="${lib.makeBinPath [ pkgs.gitMinimal ]}:$PATH"
  #    export XDG_DATA_HOME="$(mktemp -d)"
  #    gzip -dc | ${pkgs.b4}/bin/b4 -n --offline-mode am -m - -o -
  #  '';
  #  amdgpu-kernel-module = pkgs.callPackage ../../packages/kernel-module-amdgpu.nix {
  #    kernel = config.boot.kernelPackages.kernel;
  #  };
  #  amdgpu-suspend-fix = pkgs.fetchpatch {
  #    name = "amdgpu-suspend-fix";
  #    #url = "https://github.com/torvalds/linux/compare/ffd294d346d185b70e28b1a28abe367bbfe53c04...SeryogaBrigada:linux:4c55a12d64d769f925ef049dd6a92166f7841453.diff";
  #    url = "https://lore.kernel.org/amd-gfx/20251130014631.29755-1-superm1@kernel.org/t.mbox";
  #    hash = "sha256-cwhYz4QApEvJipP+iaNHCkbjRlH7iJeqEbyq08MRM4o=";
  #    decode = decodeMbox;
  #  };
  #in [
  #  (amdgpu-kernel-module.overrideAttrs (_: {
  #    patches = [
  #      amdgpu-suspend-fix
  #    ];
  #  }))
  #];
}


