{ config, pkgs, lib, ... }:
{
  services.xserver = {
    videoDrivers = ["nvidia" ];
  };

  environment.systemPackages = with pkgs; [
    nvtop-nvidia
  ];

  hardware.nvidia = {
    #package = config.boot.kernelPackages.nvidiaPackages.beta;
    powerManagement = {
      enable = true;
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

  virtualisation.docker.enableNvidia = true;

}


