{ config, pkgs, lib, ... }:
{
  services.xserver = {
    videoDrivers = ["nvidia" ];
  };

  hardware.nvidia = {
    #package = config.boot.kernelPackages.nvidiaPackages.beta;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    modesetting.enable = true; # prime.offload already does it and prime.sync needs it
    nvidiaPersistenced = true; # ensures /sys/class/drm/card0 is nvidia card, and so /dev/nvidia0 is created
    prime = {
      offload.enable = true; # enables nvidia-drm.modeset just like modesetting.enable
      #sync.enable = true; #  needs modesetting.enable
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    # Fix screen tearing by forcing full composition pipeline
    #forceFullCompositionPipeline = true;
  };

  virtualisation.docker.enableNvidia = true;

  environment.systemPackages = with pkgs; [
     # nvidia-offload
     (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec -a "$0" "$@"
    '')

  ];
}


