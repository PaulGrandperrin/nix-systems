{ config, pkgs, lib, ... }:
{
  #nixpkgs.config.cudaSupport = true;

  services.xserver = {
    videoDrivers = ["nvidia" ];
  };

  environment.systemPackages = with pkgs; [
    #nvtopPackages.nvidia # depends on CUDA which is broken
  ];

  # nixos stable doesn't always up-to-date nvidia drivers, so use the kernel packages from unstable
  #boot.kernelPackages = lib.mkDefault pkgs.unstable.linuxPackages;

  hardware.nvidia = {
    #package = config.boot.kernelPackages.nvidiaPackages.beta; # workaround https://github.com/NixOS/nixpkgs/issues/353990
    package = (config.boot.kernelPackages.callPackage (pkgs.unstable.path + "/pkgs/os-specific/linux/nvidia-x11") {}).beta; # constructs an nvidia package from unstable against our kernel
    nvidiaSettings = true;
    open = false; # not supported with 10XX series
    powerManagement = {
      enable = true;
      finegrained = true; # only works with prime.offload, not prime.sync
    };
    modesetting.enable = true; # prime.offload already does it and prime.sync needs it
    nvidiaPersistenced = true; # ensures /sys/class/drm/card0 is nvidia card, and so /dev/nvidia0 is created
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";

      offload = {
        enable = true; # enables nvidia-drm.modeset just like modesetting.enable
        enableOffloadCmd = true;
      };

      #sync.enable = true; #  needs modesetting.enable
    };
    # Fix screen tearing by forcing full composition pipeline
    #forceFullCompositionPipeline = true; # only works in sync mode, not offload
  };

  hardware.nvidia-container-toolkit.enable = true;

  #services.udev.packages = [
  #  (pkgs.writeTextFile {
  #    name = "61-mutter-primary-gpu.rules";
  #    text = ''
  #      ENV{DEVNAME}=="/dev/dri/card2", TAG+="mutter-device-preferred-primary"
  #    '';
  #    destination = "/etc/udev/rules.d/61-mutter-primary-gpu.rules";
  #  })
  #];

  #environment.sessionVariables = {
  #  MESA_VK_DEVICE_SELECT = "10de:1c8d!";
  #  GBM_BACKEND="nvidia-drm";
  #  __GLX_VENDOR_LIBRARY_NAME="nvidia";
  #  WLR_RENDERER="vulkan";
  #  MUTTER_DEBUG_KMS_THREAD_TYPE="user"; # if crashes
  #  VK_DRIVER_FILES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
  #};

}


