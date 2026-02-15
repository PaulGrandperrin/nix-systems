{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/zfs.nix
    ../shared/net.nix
    ../shared/wireguard.nix
    ../shared/wg-mounts.nix
    ../shared/desktop.nix
    ../shared/gnome.nix
    #../shared/cosmic.nix
    ../shared/desktop-i915.nix
    ../shared/nvidia.nix
    ../shared/gaming.nix
    ../shared/nspawns.nix
    ../shared/guix.nix
    ../shared/ollama.nix
    inputs.lanzaboote.nixosModules.lanzaboote
    #inputs.nix-cluster.nixosModules.nix-cluster
    #inputs.nar-alike-deduper.nixosModules.default
  ];

  # use latest ZFS compatible linux kernel from unstable
  # manually evaluate `latest-zfs-kernel` to set its `pkgs` to `pkgs.unstable`
  boot.kernelPackages = ((import "${inputs.srvos}/nixos/mixins/latest-zfs-kernel.nix") {inherit lib config; pkgs= pkgs.unstable;}).boot.kernelPackages;
  boot.zfs.package = lib.mkForce pkgs.unstable.zfs_2_4; # also take zfs userspace from unstable for versions to be in sync

  #boot.kernelPackages = (import inputs.nixos-linux_6_16 {
  #  system = pkgs.stdenv.hostPlatform.system;
  #  config = import ../../nixpkgs/config.nix;
  #}).linuxKernel.packages.linux_6_16;

  #boot.kernelPackages = let # from https://wiki.nixos.org/wiki/ZFS#Selecting_the_latest_ZFS-compatible_Kernel
  #  zfsCompatibleKernelPackages = lib.filterAttrs (
  #    name: kernelPackages:
  #    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
  #    && (builtins.tryEval kernelPackages).success
  #    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  #  ) pkgs.unstable.linuxKernel.packages; # take kernel from unstable
  #in lib.last (
  #  lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
  #    builtins.attrValues zfsCompatibleKernelPackages
  #  )
  #);

  #boot.zfs.package = lib.mkForce pkgs.unstable.zfs; # also take zfs userspace from unstable for versions to be in sync
  #boot.zfs.modulePackage = config.boot.kernelPackages.callPackage (pkgs.unstable.path + "/pkgs/os-specific/linux/zfs/2_3.nix") {configFile = "kernel";};

  home-manager.users = let 
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
        ../../homeModules/shared/cmdline-extra.nix
        ../../homeModules/shared/firefox.nix
        ../../homeModules/shared/chromium.nix
        ../../homeModules/shared/desktop-linux.nix
        ../../homeModules/shared/gnome.nix
        #../../homeModules/shared/kodi.nix
        #../../homeModules/shared/rust.nix
        ../../homeModules/shared/wine.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  #services.nixCluster.server.enable = true;
  #nar-alike-deduper.enable = true;

  fileSystems."/" = {
    device = "ssd/encrypted/nixos";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/home" = {
    device = "ssd/encrypted/nixos/home";
    fsType = "zfs";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/boot" = {
    #device = "/dev/disk/by-uuid/1189-72D1";
    device = "/dev/disk/by-partlabel/boot1";
    fsType = "vfat";
    options = [
      "noatime"
      "nodiratime"
      "nofail"
    ];
  };

  nix.settings = {
    cores = 4; # max concurrent tasks during one build
    max-jobs = 4; # max concurrent build job
  };

  # audio is broken on 6.7
  # https://bbs.archlinux.org/viewtopic.php?id=292297
  # https://bbs.archlinux.org/viewtopic.php?pid=2148028#p2148028
  #boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_6;
  boot.blacklistedKernelModules = [
    "snd_soc_avs"
  ];

  swapDevices = [ ];

  networking.hostId="7ee1da4a";
  networking.hostName = "nixos-xps";
  services.net = {
    enable = true;
    mainInt = "wlp2s0";
  };

  services.my-wg = {
    enable = true;
  };

  paulg.ollama.enable = true;

  services.thermald.enable = false; # should be disabled when throttled is enabled
  services.throttled.enable = true;

  hardware.nvidia.open = false; # not supported on Pascal microarch

  #hardware.graphics = {
  #  package = pkgs.unstable.mesa;
  #  extraPackages = with pkgs.unstable; [
  #    intel-media-driver
  #  ];
  #  package32 = pkgs.unstable.pkgsi686Linux.mesa;
  #  extraPackages32 = with pkgs.unstable.pkgsi686Linux; [
  #    intel-media-driver
  #  ];
  #};

  #virtualisation.my-nspawn = {
  #  enable = true;
  #  wan-if = "wlp2s0";
  #  containers = {
  #    test = {
  #      id = 1;
  #      mac = "02:7a:7c:64:3a:46";
  #      ports = [
  #      ];
  #      max-mem="4G";
  #      os = "debian";
  #    };
  #    test2 = {
  #      id = 2;
  #      mac = "2a:ef:5b:b5:ad:e5";
  #      ports = [
  #      ];
  #      max-mem="4G";
  #      os = "nixos";
  #    };
  #  };
  #};

  systemd.services.smbios-thermal = {
    script = ''
      ${pkgs.libsmbios}/bin/smbios-thermal-ctl --set-thermal-mode quiet || true # obsolete since linux 6.11
      echo quiet > /sys/firmware/acpi/platform_profile || true
    '';
    wantedBy = [ "multi-user.target" ];
  };

  zramSwap.enable = lib.mkForce true;

  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=170000" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)#Enable_NVMe_APST and https://wiki.archlinux.org/title/Solid_state_drive/NVMe#Power_Saving_(APST)
    "enable_psr=1" "disable_power_well=0" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)#Enable_power_saving_features_for_the_i915_kernel_module
    #"acpi_rev_override=1" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)
    "mitigations=off"
  ];

  # Secure boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };
  boot.initrd.systemd = let
    challenge = pkgs.writeText "challenge" "bf239fcf13ad263cb235eaa4aa6709a4cc8c0e843fa921bccbf083e70a3619f3  /sysroot/etc/secureboot/keys/PK/PK.key"; # don't forget to prepend /sysroot
  in {
    emergencyAccess = "$6$L5luqeVnXrobIl$TyGUOBnB.jvLxdq7t70TFFKkPbfkSqkN.fx8rU3rAomJhZjCBsTZkhC3CIDBFVQjNslcDmExjnGHjDT7TNHIR0";

    storePaths = [ pkgs.coreutils challenge];
    services.challenge-root-fs = {
      requires = ["initrd-root-fs.target"];
      after = ["initrd-root-fs.target"];
      requiredBy = ["initrd-parse-etc.service"];
      before = ["initrd-parse-etc.service"];
      unitConfig.AssertPathExists = "/etc/initrd-release";
      serviceConfig.Type = "oneshot";
      description = "Challenging the authenticity of the root FS";
      script = ''
        ${pkgs.coreutils}/bin/sha256sum -c ${challenge}
      '';
    };
  };
  boot.plymouth.tpm2-totp.enable = true;

  specialisation = {
    "Rescue" = {
      inheritParentConfig = true; # defaults to true
      configuration = {
        boot.plymouth.enable = lib.mkForce false;
        system.nixos.tags = [ "rescue" ];
        boot.kernelParams = [ "rd.rescue" ];
      };
    };
  };


}

