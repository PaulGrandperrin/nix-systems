{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/zfs.nix
    ../shared/net.nix
    #../shared/wireguard.nix
    #../shared/wg-mounts.nix
    ../shared/desktop.nix
    ../shared/desktop-radeon.nix
    ../shared/gnome.nix
    ../shared/cosmic.nix
    ../shared/gaming.nix
    #../shared/nspawns.nix
    #../shared/guix.nix
    ../shared/ollama.nix
    ../shared/lid-killswitch.nix
    ../shared/modprobed-db.nix
    #inputs.lanzaboote.nixosModules.lanzaboote
    #inputs.nix-cluster.nixosModules.nix-cluster
    #inputs.nar-alike-deduper.nixosModules.default
  ];

  # use latest ZFS compatible linux kernel from unstable
  # manually evaluate `latest-zfs-kernel` to set its `pkgs` to `pkgs.unstable`
  #boot.kernelPackages = ((import "${inputs.srvos}/nixos/mixins/latest-zfs-kernel.nix") {inherit lib config; pkgs = pkgs.unstable;}).boot.kernelPackages;

  boot.kernelPackages = pkgs.unstable.linuxPackagesFor (pkgs.unstable.linux_6_18.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
            hash = "sha256-4AMpStTCwqxbt3+7gllRETT1HZh7MhJRaDLcSwyD8eo=";
      };
      version = "6.18.12";
      modDirVersion = version;
    };
  });
  

  #boot.kernelPackages = (import inputs.kernel {
  #  system = pkgs.stdenv.hostPlatform.system;
  #  config = import ../../nixpkgs/config.nix;
  #}).linuxKernel.packages.linux_6_17;

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

  boot.zfs.package = lib.mkForce pkgs.unstable.zfs_2_4; # also take zfs userspace from unstable for versions to be in sync
  #boot.zfs.modulePackage = config.boot.kernelPackages.callPackage (pkgs.unstable.path + "/pkgs/os-specific/linux/zfs/2_4.nix") {configFile = "kernel";};

  boot.zfs.allowHibernation = true; # ok because our swap in on a dedicated partition and we use systemd initrd

  home-manager.users = let 
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
        ../../homeModules/shared/cmdline-extra.nix
        ../../homeModules/shared/firefox.nix
        #../../homeModules/shared/chromium.nix
        ../../homeModules/shared/desktop-linux.nix
        ../../homeModules/shared/gnome.nix
        #../../homeModules/shared/kodi.nix
        #../../homeModules/shared/rust.nix
        #../../homeModules/shared/wine.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  #services.nixCluster.server.enable = true;
  #nar-alike-deduper.enable = true;

  fileSystems."/" = {
    device = "zpool/encrypted/nixos";
    fsType = "zfs";
    options = [
      "zfsutil" # needed because of mountpoint=none
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/home" = {
    device = "zpool/encrypted/nixos/home";
    fsType = "zfs";
    options = [
      "zfsutil" # needed because of mountpoint=none
      "noatime"
      "nodiratime"
    ];
  };

  fileSystems."/home/paulg/torrents" = {
    device = "zpool/encrypted/nixos/home/paulg_torrents";
    fsType = "zfs";
    options = [
      "zfsutil" # needed because of mountpoint=none
      "noatime"
      "nodiratime"
      "nofail"
    ];
  };

  fileSystems."/home/paulg/ntfs" = {
    device = "/dev/disk/by-partlabel/ntfs";
    fsType = "ntfs3";
    options = [
      "windows_names"
      "prealloc"
      "noatime"
      "nodiratime"
      "nofail"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/nixos_boot";
    fsType = "vfat";
    options = [
      "umask=077"
      "noatime"
      "nodiratime"
      "nofail"
    ];
  };

  swapDevices = [{
    device = config.boot.resumeDevice;
    options = ["nofail"];
    discardPolicy = "both";
    encrypted = {
      enable = true;
      label = "swap";
      blkDev = "/dev/disk/by-partlabel/encrypted_swap";
    };
  }];

  # cryptsetup luksFormat /dev/disk/by-partlabel/encrypted_swap \
  #  --type luks2 \
  #  --sector-size 4096 \
  #  --key-size 256 \ # equivalent to AES-128, which is enough when ignoring quantum attacks
  #  --iter-time 1000  # strong password don't require long iterations
  #  # more modern and authentificated, but doesn't yet support discards
  #  --cipher aegis128-random \
  #  --integrity aead \
  #  --key-size 128
  
  # cryptsetup luksOpen /dev/disk/by-partlabel/encrypted_swap swap
  # mkswap -L swap /dev/mapper/swap

  boot = {
    resumeDevice = "/dev/mapper/swap";
    initrd.luks = {
      #cryptoModules = lib.mkAfter [ # needed when using aegis but maybe not enough because it doesn't work
      #  "aegis128"
      #  "aegis128_aesni"
      #  "dm_integrity" # async_xor # async_tx # xor # dm_bufio
      #];
      devices."swap" = {
        # device option is already filled by swapDevices[].encrypted.blkDev
        allowDiscards = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    cryptsetup
  ];

  #nix.settings = {
  #  cores = 4; # max concurrent tasks during one build
  #  max-jobs = 4; # max concurrent build job
  #};

  networking.hostId="367cd464"; # needed by ZFS: head -c 8 /etc/machine-id
  networking.hostName = "nixos-g1a";
  services.net = {
    enable = true;
    mainInt = "wlp193s0";
  };

  #services.my-wg = {
  #  enable = true;
  #};

  #paulg.ollama.enable = true;

  #services.thermald.enable = false; # should be disabled when throttled is enabled
  #services.throttled.enable = true;

  hardware.graphics = let
    # TODO add wayland-protocol-git ??
    libdrm_override_fn = finalAttrs: previousAttrs: rec {
      version = "git";
      src = pkgs.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "mesa";
        repo = "libdrm";
        rev = "369990d9660a387f618d0eedc341eb285016243b";
        hash = "sha256-kOaTjBeo4IsfWEk/JBTNId5ikrnpoc9DEjIl7DUd2yE=";
      };
    };
    mesa_override_fn = finalAttrs: previousAttrs: rec {
      version = "26.0.0-rc3";
      src = pkgs.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "mesa";
        repo = "mesa";
        rev = "mesa-${version}";
        hash = "sha256-4s8VDh1T9IW334JS4kXIx27O0MqN210pP4kTzHyVriI=";
      };
      patches = builtins.filter (p: baseNameOf p != "musl.patch") previousAttrs.patches;
    };
  in {
    package = pkgs.unstable.mesa;
    package32 = pkgs.unstable.pkgsi686Linux.mesa;
    #package = ((pkgs.unstable.mesa.override {
    #  libdrm = (pkgs.unstable.libdrm.overrideAttrs libdrm_override_fn);
    #}).overrideAttrs mesa_override_fn);
    #package32 = ((pkgs.unstable.pkgsi686Linux.mesa.override {
    #  libdrm = (pkgs.unstable.pkgsi686Linux.libdrm.overrideAttrs libdrm_override_fn);
    #}).overrideAttrs mesa_override_fn);
    #extraPackages = with pkgs.unstable; [];
    #extraPackages32 = with pkgs.unstable.pkgsi686Linux; [];
  };

  ## might increase compatibility but needs --impure
  ## might need https://github.com/chaotic-cx/nyx/blob/aacb796ccd42be1555196c20013b9b674b71df75/pkgs/mesa-git/default.nix#L54
  #replaceConfig = {
  #  system.replaceDependencies.replacements = [
  #    {
  #      oldDependency = pkgs.mesa.out;
  #      newDependency = pkgs.mesa_git.out;
  #    }
  #    {
  #      oldDependency = pkgs.pkgsi686Linux.mesa.out;
  #      newDependency = pkgs.mesa32_git.out;
  #    }
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

  #systemd.services.smbios-thermal = {
  #  script = ''
  #    ${pkgs.libsmbios}/bin/smbios-thermal-ctl --set-thermal-mode quiet || true # obsolete since linux 6.11
  #    echo quiet > /sys/firmware/acpi/platform_profile || true
  #  '';
  #  wantedBy = [ "multi-user.target" ];
  #};

  zramSwap.enable = lib.mkForce false; # TODO enable zswap

  services.thermald.enable = lib.mkForce false; # mostly intel specific but shouldn't conflict with ppd
  services.power-profiles-daemon.enable = lib.mkForce true; # /sys/firmware/acpi/platform_profile_choices
  boot.kernelParams = [
  #"amd_pstate=active" # useless as it's the default
  #  "pcie_aspm=force" 
  #  "pcie_aspm.policy=powersave"
  #  "idle=nomwait"
  ];

  #services.udev.extraRules = '' # gemini generated ideas
  #  # Enable runtime power management for all PCI devices
  #  ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
  #  
  #  # Specifically target the AMD Audio and GPU controllers which often block C6
  #  ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1002", ATTR{power/control}="auto"
  #'';

  #powerManagement = {
  #  powerDownCommands = lib.mkBefore ''
  #    #modprobe -r mt7925e
  #    ${pkgs.kmod}/bin/rmmod mt7925e
  #    #echo disabled > /sys/bus/pci/devices/0000:03:00.0/power/wakeup # ARPT in /proc/acpi/wakeup, wifi adapter always wakes up the machine, already disabled by rmmod

  #    ## if the LID is open
  #    #if grep open /proc/acpi/button/lid/LID0/state; then
  #    #  # disable the open-lid sensor but enable the keyboard (USB) wake up events
  #    #  echo enabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup # XHC1 in /proc/acpi/wakeup, USB controller, sometimes wakes up the machine
  #    #  echo disabled > /sys/bus/acpi/devices/PNP0C0D:00/power/wakeup # LID0 in /proc/acpi/wakeup, wakes up the machine when the lid is in open position
  #    #else 
  #    #  # enable the open-lid sensor wake events but disable to USB controller to be extra sure
  #    #  echo enabled > /sys/bus/acpi/devices/PNP0C0D:00/power/wakeup # LID0 in /proc/acpi/wakeup, wakes up the machine when the lid is in open position
  #    #  echo disabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup # XHC1 in /proc/acpi/wakeup, USB controller, sometimes wakes up the machine
  #    #fi
  #  '';
  #  powerUpCommands = lib.mkBefore ''[ "$IN_NIXOS_SYSTEMD_STAGE1" = "true" ] || ${pkgs.kmod}/bin/modprobe mt7925e''; # must not run in stage1 because module loading is not ready yet
  #};

  ## Secure boot
  #boot.loader.systemd-boot.enable = lib.mkForce false;
  #boot.lanzaboote = {
  #  enable = true;
  #  pkiBundle = "/etc/secureboot";
  #};
  #boot.initrd.systemd = let
  #  challenge = pkgs.writeText "challenge" "bf239fcf13ad263cb235eaa4aa6709a4cc8c0e843fa921bccbf083e70a3619f3  /sysroot/etc/secureboot/keys/PK/PK.key"; # don't forget to prepend /sysroot
  #in {
  #  emergencyAccess = "$6$L5luqeVnXrobIl$TyGUOBnB.jvLxdq7t70TFFKkPbfkSqkN.fx8rU3rAomJhZjCBsTZkhC3CIDBFVQjNslcDmExjnGHjDT7TNHIR0";

  #  storePaths = [ pkgs.coreutils challenge];
  #  services.challenge-root-fs = {
  #    requires = ["initrd-root-fs.target"];
  #    after = ["initrd-root-fs.target"];
  #    requiredBy = ["initrd-parse-etc.service"];
  #    before = ["initrd-parse-etc.service"];
  #    unitConfig.AssertPathExists = "/etc/initrd-release";
  #    serviceConfig.Type = "oneshot";
  #    description = "Challenging the authenticity of the root FS";
  #    script = ''
  #      ${pkgs.coreutils}/bin/sha256sum -c ${challenge}
  #    '';
  #  };
  #};
  #boot.plymouth.tpm2-totp.enable = true;

  #specialisation = {
  #  "Rescue" = {
  #    inheritParentConfig = true; # defaults to true
  #    configuration = {
  #      boot.plymouth.enable = lib.mkForce false;
  #      system.nixos.tags = [ "rescue" ];
  #      boot.kernelParams = [ "rd.rescue" ];
  #    };
  #  };
  #};

  services.fprintd = {
    enable = true;
  };
}

