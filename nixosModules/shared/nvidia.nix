{ config, pkgs, lib, ... }:
{
  services.xserver = {
    videoDrivers = ["nvidia" ];
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

  # nixos stable doesn't always up-to-date nvidia drivers, so use the kernel packages from unstable
  #boot.kernelPackages = lib.mkDefault pkgs.unstable.linuxPackages;

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta; # workaround https://github.com/NixOS/nixpkgs/issues/353990
    powerManagement = {
      #enable = true; # cause restart loop https://github.com/NixOS/nixpkgs/issues/336723
      finegrained = true;
    };
    modesetting.enable = true; # prime.offload already does it and prime.sync needs it
    nvidiaPersistenced = true; # ensures /sys/class/drm/card0 is nvidia card, and so /dev/nvidia0 is created
    prime = {
      offload = {
        enable = true; # enables nvidia-drm.modeset just like modesetting.enable
        enableOffloadCmd = true;
      };
      #sync.enable = true; #  needs modesetting.enable
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    # Fix screen tearing by forcing full composition pipeline
    #forceFullCompositionPipeline = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

}


