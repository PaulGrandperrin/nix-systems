{config, lib, options, pkgs, modulesPath, ...}:{
  imports =
    [
      # Profiles of this basic installation CD.
      "${toString modulesPath}/profiles/all-hardware.nix"
      "${toString modulesPath}/profiles/base.nix"

      # Enable devices which are usually scanned, because we don't know the
      # target system.
      "${toString modulesPath}/installer/scan/detected.nix"
      "${toString modulesPath}/installer/scan/not-detected.nix"
    ];

  # Automatically log in at the virtual consoles.
  services.getty.autologinUser = "paulg";

  # To speed up installation a little bit, include the complete
  # stdenv in the Nix store on the CD.
  system.extraDependencies = with pkgs; [
    #stdenv
    #stdenvNoCC # for runCommand
    #busybox
    #jq # for closureInfo
    ## For boot.initrd.systemd
    #makeInitrdNGTool
    #systemdStage1
    #systemdStage1Network
  ];

  # Prevent installation media from evacuating persistent storage, as their
  # var directory is not persistent and it would thus result in deletion of
  # those entries.
  environment.etc."systemd/pstore.conf".text = ''
    [PStore]
    Unlink=no
  '';

  # ISO naming.
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";

  # Add Memtest86+ to the CD.
  boot.loader.grub.memtest86.enable = true;
  
  # An installation media cannot tolerate a host config defined file
  # system layout on a fresh machine, before it has been formatted.
  swapDevices = lib.mkImageMediaOverride [ ];
  fileSystems = lib.mkImageMediaOverride config.lib.isoFileSystems;
  
  #boot.postBootCommands = ''
  #  for o in $(</proc/cmdline); do
  #    case "$o" in
  #      live.nixos.passwd=*)
  #        set -- $(IFS==; echo $o)
  #        echo "nixos:$2" | ${pkgs.shadow}/bin/chpasswd
  #        ;;
  #    esac
  #  done
  #'';
  
  system.stateVersion = lib.mkDefault lib.trivial.release;

}
