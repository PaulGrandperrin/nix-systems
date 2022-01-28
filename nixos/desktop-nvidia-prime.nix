{ config, pkgs, lib, ... }:
{
  services.xserver = {
    videoDrivers = ["nvidia" ]; # TODO try alone, without hardware.nvidia

    displayManager.gdm.nvidiaWayland = true; # remove the udev rules which disables wayland when the nvidia driver is loaded

    # Fix screen tearing by forcing full composition pipeline
    screenSection = ''
      Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
      Option         "AllowIndirectGLXProtocol" "off"
      Option         "TripleBuffer" "on"
    '';
  };

  hardware.nvidia = { # TODO try alone
    package = config.boot.kernelPackages.nvidiaPackages.beta;
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
  };

  environment.systemPackages = with pkgs; [
     # nvidia-offload
     (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec -a "$0" "$@"
    '')

    gst_all_1.gst-vaapi # nix shell nixos#gst_all_1.gstreamer.dev gst-inspect-1.0 vaapi
  ];

  environment.sessionVariables = { # works for all kinds of sessions whereas environment.variables (/etc/profile) only works for interactive shells
    LIBVA_DRIVER_NAME = "iHD";
    #LIBVA_DRIVER_NAME = "i965";
    VDPAU_DRIVER = "va_gl";
  };

  # TODO why /dev/dri/by-path/pci-0000:00:02.0-render and not /dev/dri/renderD128 ? udev ? needed for ffmpeg

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; }; # allows the use of old "i965 VA driver"
  };


  boot.extraModprobeConfig = '' # not included in stage1: https://github.com/NixOS/nixpkgs/pull/145013
    options i915 enable_guc=2 # necessary for AVC/HEVC/VP9 low power encoding bitrate control: https://github.com/intel/media-driver#known-issues-and-limitations, check with sudo cat /sys/module/i915/parameters/enable_guc
  '';

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      
      # OpenCL
      #intel-ocl # replaced by intel-compute-runtime (neo)
      #beignet # replaced by intel-compute-runtime (neo)
      #intel-compute-runtime # (neo)
      #ocl-icd 
      #khronos-ocl-icd-loader
    ];
  }; 

}


