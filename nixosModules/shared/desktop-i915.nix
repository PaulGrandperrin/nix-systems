{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    gst_all_1.gst-vaapi # nix shell nixos#gst_all_1.gstreamer.dev gst-inspect-1.0 vaapi FIXME not present in GST_PLUGIN_SYSTEM_PATH_1_0
  ];

  environment.sessionVariables = { # works for all kinds of sessions whereas environment.variables (/etc/profile) only works for interactive shells
    LIBVA_DRIVER_NAME = "iHD";
    #LIBVA_DRIVER_NAME = "i965";
    VDPAU_DRIVER = "va_gl";
  };

  # TODO why /dev/dri/by-path/pci-0000:00:02.0-render and not /dev/dri/renderD128 ? udev ? needed for ffmpeg

  #nixpkgs.config.packageOverrides = pkgs: {
  #  vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; }; # allows the use of old "i965 VA driver"
  #};


  boot.extraModprobeConfig = ''
    # not included in stage1: https://github.com/NixOS/nixpkgs/pull/145013
    # necessary for AVC/HEVC/VP9 low power encoding bitrate control: https://github.com/intel/media-driver#known-issues-and-limitations, check with sudo cat /sys/module/i915/parameters/enable_guc
    options i915 enable_guc=2
  '';

  hardware.graphics = {
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


