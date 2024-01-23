{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    ../shared/zfs.nix
    ../shared/net.nix
    ../shared/wireguard.nix
    ../shared/wg-mounts.nix
    ../shared/desktop.nix
    ../shared/desktop-i915.nix
    ../shared/nvidia.nix
    ../shared/gaming.nix
    inputs.lanzaboote.nixosModules.lanzaboote
    #inputs.nix-cluster.nixosModules.nix-cluster
  ];

  home-manager.users = let 
    homeModule = {
      imports = [
        ../../homeModules/shared/core.nix
        ../../homeModules/shared/cmdline-extra.nix
        ../../homeModules/shared/firefox.nix
        ../../homeModules/shared/chromium.nix
        ../../homeModules/shared/desktop-linux.nix
        ../../homeModules/shared/gnome.nix
        ../../homeModules/shared/kodi.nix
        ../../homeModules/shared/rust.nix
        ../../homeModules/shared/wine.nix
      ];
    };
  in {
    root  = homeModule;
    paulg = homeModule;
  };

  #services.nix-cluster.server.enable = true;

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
    device = "/dev/disk/by-uuid/ACA7-12F3";
    fsType = "vfat";
    options = [
      "noatime"
      "nodiratime"
    ];
  };

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

  services.thermald.enable = false; # should be disabled when throttled is enabled
  services.throttled.enable = true;

  systemd.services.smbios-thermal = {
    script = ''
      ${pkgs.libsmbios}/bin/smbios-thermal-ctl --set-thermal-mode quiet
    '';
    wantedBy = [ "multi-user.target" ];
  };

  zramSwap.enable = lib.mkForce false;

  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=170000" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)#Enable_NVMe_APST and https://wiki.archlinux.org/title/Solid_state_drive/NVMe#Power_Saving_(APST)
    "enable_psr=1" "disable_power_well=0" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)#Enable_power_saving_features_for_the_i915_kernel_module
    #"acpi_rev_override=1" # https://wiki.archlinux.org/title/Dell_XPS_15_(9560)
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

  services.etcd = {
    enable = true;
  };

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

