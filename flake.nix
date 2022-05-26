{

  description = "Paul Grandperrin NixOS confs";

  inputs = {
    nixos-22-05.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-22-05-small.url = "github:NixOS/nixpkgs/nixos-22.05-small";
    nixpkgs-22-05-darwin.url = "github:NixOS/nixpkgs/nixpkgs-22.05-darwin";

    nur.url = "github:nix-community/NUR";

    nix-on-droid = {
      url = "github:t184256/nix-on-droid/testing";
      inputs.nixpkgs.follows = "nixos-22-05"; # TODO try to remove
      inputs.flake-utils.follows = "flake-utils";
      inputs.home-manager.follows = "home-manager-22-05"; # TODO try to remove
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-22-05-darwin"; # FIXME only used to access lib...
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = ""; # not used because we use the overlay
      inputs.flake-utils.follows = "flake-utils";
    };

    home-manager-22-05 = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = ""; # doesn't matter because we use home-manager.useGlobalPkgs = true
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = ""; # doesn't matter because we use the nixosModule
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixos-22-05"; # TODO the overlay is using it, but I would like it to not use it
    };

    nixgl = {
      url = "github:guibou/nixGL";
      flake = false; # TODO it's now a flake!
    };
  };


  outputs = inputs: let 
    getOverlays = system: let # FIXME not sure those are the good channels for darwin
      pkgs-22-05 = inputs.nixos-22-05.legacyPackages.${system};
      #unstable-pkgs = inputs.nixos-unstable.legacyPackages.${system};
      #unstable-overlay = final: prev: { unstable = unstable-pkgs; };
    in
      [ inputs.nur.overlay inputs.rust-overlay.overlay inputs.nix-alien.overlay];
  in {

    packages.x86_64-linux.vcv-rack = inputs.nixos-22-05.legacyPackages.x86_64-linux.callPackage ./pkgs/vcv-rack {};

    #devShell.x86_64-linux = stable-pkgs.mkShell {
    #    buildInputs = with stable-pkgs; [
    #      cowsay
    #      fish
    #    ];

    #    shellHook = ''
    #      cowsay "Welcome"
    #    '';
    #  }
    #;

    nixOnDroidConfigurations = {
      pixel6pro = inputs.nix-on-droid.lib.nixOnDroidConfiguration rec {
        system = "aarch64-linux";
        config = {pkgs, ...}: {
          user.shell = "${pkgs.fish}/bin/fish";
          nix.package = pkgs.nixFlakes;
          home-manager = {
            extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nix-on-droid.inputs.nixpkgs; installDesktopApp = false; is_unstable = true;};
            config = {pkgs, lib, config, ...}: {
              imports = [./home-manager/cmdline.nix];
              nixpkgs.overlays = getOverlays system;
              home.activation = {
                copyFont = let 
                    font_src = "${pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; }}/share/fonts/truetype/NerdFonts/Fira Code Regular Nerd Font Complete Mono.ttf";
                    font_dst = "${config.home.homeDirectory}/.termux/font.ttf";
                  in lib.hm.dag.entryAfter ["writeBoundary"] ''
                    ( test ! -e "${font_dst}" || test $(sha1sum "${font_src}"|cut -d' ' -f1 ) != $(sha1sum "${font_dst}" |cut -d' ' -f1)) && $DRY_RUN_CMD install $VERBOSE_ARG -D "${font_src}" "${font_dst}"
                '';
              };
              home.packages = [
                (pkgs.writeShellScriptBin "start_sshd" ''${pkgs.openssh}/bin/sshd -f ${config.home.homeDirectory}/sshd/sshd_config'')
              ];
            };
          };
	};
        extraModules = [];
      };
    };

    homeConfigurations = {
      paulg-x86_64-linux = inputs.home-manager-22-05.lib.homeManagerConfiguration rec {
        system = "x86_64-linux";
        homeDirectory = "/home/paulg";
        username = "paulg";
        extraSpecialArgs = {inherit system inputs; mainFlake = inputs.home-manager-22-05.inputs.nixpkgs; installDesktopApp = false; is_unstable = true;};
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./home-manager/cmdline.nix ./home-manager/desktop.nix];
          nixpkgs.overlays = getOverlays system;
          nixpkgs.config.allowUnfree = true;
          home.packages = [
            (pkgs.writeShellScriptBin "nixGLNvidia" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A auto.nixGLNvidia --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixGLIntel" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A nixGLIntel --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixVulkanIntel" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A nixVulkanIntel --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixVulkanNvidia" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A auto.nixVulkanNvidia --no-out-link)/bin/* "$@"'')
          ];
        };
      };
      paulg-aarch64-darwin = inputs.home-manager-22-05.lib.homeManagerConfiguration rec {
        system = "aarch64-darwin";
        homeDirectory = "/Users/paulg";
        username = "paulg";
        extraSpecialArgs = {inherit system inputs; mainFlake = inputs.home-manager-22-05.inputs.nixpkgs; installDesktopApp = false; is_unstable = true;};
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./home-manager/cmdline.nix ./home-manager/desktop.nix ./home-manager/desktop-macos.nix];
          nixpkgs.overlays = getOverlays system;
          nixpkgs.config.allowUnfree = true;
        };  
      };
    };

    darwinConfigurations = let
      mkDarwinConf = arch: let
          inputs-patched = inputs // {nixpkgs = inputs.nixpkgs-22-05-darwin; darwin = inputs.nix-darwin;};
        in inputs-patched.darwin.lib.darwinSystem rec {
          system = "${arch}-darwin";
          inputs = inputs-patched; # otherwise it would take this flake's inputs and expect nixpkgs and darwin to be hardcoded
          specialArgs = { inherit system inputs; }; #  passes inputs to modules
          modules = [
            { 
              nixpkgs = {
                overlays = getOverlays system;
                config.allowUnfree = true;
              };
            }
            ./nix-darwin/common.nix
            inputs.home-manager-22-05.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixpkgs; is_nixos = false;};
              home-manager.users.root  = { imports = [./home-manager/cmdline.nix];};
              home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/desktop.nix ./home-manager/desktop-macos.nix ./home-manager/rust-stable.nix];};
            }
          ];
        };
    in {
      "MacBookPaul" = mkDarwinConf "x86_64";
      "MacMiniPaul" = mkDarwinConf "x86_64";
    };

    # Used with `nixos-rebuild --flake .#<hostname>`
    # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
    nixosConfigurations = let
      mkNixosConf = arch: channel: nixos-modules: hm-modules: inputs.${channel}.lib.nixosSystem rec {
        system = "${arch}-linux";
        specialArgs = { inherit system inputs channel; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {overlays = getOverlays system; }; }
          inputs.home-manager-22-05.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true; # means that pkgs are taken from the nixosSystem and not from home-manager.inputs.nixpkgs
            home-manager.useUserPackages = true; # means that pkgs are installed at /etc/profiles instead of $HOME/.nix-profile
            home-manager.extraSpecialArgs = {inherit system inputs;  mainFlake = inputs.${channel}; is_nixos = true;};
            home-manager.users.root  = { imports = hm-modules;};
            home-manager.users.paulg = { imports = hm-modules;};
          }
          inputs.nix-ld.nixosModules.nix-ld
        ] ++ nixos-modules;
      };
    in { 
      nixos-nas = mkNixosConf "x86_64" "nixos-22-05-small" [
        ./nixos/hosts/nas/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/nspawns/ubuntu.nix
        ./nixos/net.nix
        ./nixos/auto-upgrade.nix
        {
          networking.hostId="51079489";
          networking.hostName = "nixos-nas";
          services.net = {
            enable = true;
            mainInt = "enp3s0";
          }; 
        }
      ]
      [
        ./home-manager/cmdline.nix
      ];

      nixos-gcp = mkNixosConf "x86_64" "nixos-22-05-small" [
        ./nixos/hosts/gcp/hardware-configuration.nix
        ./nixos/google-compute-config.nix
        ./nixos/common.nix
        ./nixos/containers/web.nix
        # ./nixos/auto-upgrade.nix # 1G of memory is not enough to evaluate the system's derivation, even with zram...
        ({pkgs, lib, ...}:{
          networking.hostId = "1c734661"; # for ZFS
          networking.hostName = "nixos-gcp";
          networking.interfaces.eth0.useDHCP = true;
          
          # useful to build and deploy closures from nixos-xps which a lot beefier than nixos-gcp
          users.users.root.openssh.authorizedKeys.keys = [ 
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2" # root@nixos-xps
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57" # root@MacBookPaul NixOS
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY" # root@nixos-nas
          ];
          
          services.smartd.enable = lib.mkForce false;
        
          environment.systemPackages = with pkgs; [
            google-cloud-sdk-gce
          ];
        })
      ]
      [
        ./home-manager/cmdline.nix
      ];

      nixos-xps = mkNixosConf "x86_64" "nixos-22-05" [
        ./nixos/hosts/xps/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/laptop.nix
        ./nixos/desktop.nix
        ./nixos/desktop-i915.nix
        ./nixos/nvidia.nix
        {
          networking.hostId="7ee1da4a";
          networking.hostName = "nixos-xps";
          services.net = {
            enable = true;
            mainInt = "wlp2s0";
          };
          systemd.network.wait-online = {
            timeout = 10;
            extraArgs = ["-i" "wlan0"]; # FIXME why --any isn't working? 
          };
        }
      ]
      [
        ./home-manager/cmdline.nix
        ./home-manager/desktop.nix
        ./home-manager/desktop-linux.nix
        ./home-manager/rust-nightly.nix
      ];

      MacBookPaul = mkNixosConf "x86_64" "nixos-22-05" [
        ./nixos/hosts/MacBookPaul/hardware-configuration.nix
        ./nixos/common.nix
        ./nixos/net.nix
        ./nixos/laptop.nix
        ./nixos/desktop.nix
        ./nixos/desktop-i915.nix
        ({pkgs, lib, ...}:{
          networking.hostId="f2b2467d";
          hardware.facetimehd.enable = true;
          services.mbpfan.enable = true;

          programs.nix-ld.enable = true;

          powerManagement = {
            powerDownCommands = lib.mkBefore ''
              # brcmfmac being loaded during hibernation would not let a successful resume
              # https://bugzilla.kernel.org/show_bug.cgi?id=101681#c116.
              # Also brcmfmac could randomly crash on resume from sleep.
              # And also, brcmfac prevents suspending
              ${pkgs.kmod}/bin/rmmod brcmfmac
              #echo disabled > /sys/bus/pci/devices/0000:03:00.0/power/wakeup # ARPT in /proc/acpi/wakeup, wifi adapter always wakes up the machine, already disabled by rmmod

              # if the LID is open
              if grep open /proc/acpi/button/lid/LID0/state; then
                # disable the open-lid sensor but enable the keyboard (USB) wake up events
                echo enabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup # XHC1 in /proc/acpi/wakeup, USB controller, sometimes wakes up the machine
                echo disabled > /sys/bus/acpi/devices/PNP0C0D:00/power/wakeup # LID0 in /proc/acpi/wakeup, wakes up the machine when the lid is in open position
              else 
                # enable the open-lid sensor wake events but disable to USB controller to be extra sure
                echo enabled > /sys/bus/acpi/devices/PNP0C0D:00/power/wakeup # LID0 in /proc/acpi/wakeup, wakes up the machine when the lid is in open position
                echo disabled > /sys/bus/pci/devices/0000:00:14.0/power/wakeup # XHC1 in /proc/acpi/wakeup, USB controller, sometimes wakes up the machine
              fi
            '';
            powerUpCommands = lib.mkBefore "${pkgs.kmod}/bin/modprobe brcmfmac";
          };

          # USB subsystem wakes up MBP right after suspend unless we disable it.
          #services.udev.extraRules = ''
          #  ### fix suspend on MacBookPro12,1 
          #  # found using:
          #  # cat /proc/acpi/wakeup
          #  # echo $device > /proc/acpi/wakeup # to bruteforce which devices woke up the laptop
          #  # fd $sysfs_node /sys
          #  # udevadm info -a -p $path
          #  #SUBSYSTEM=="pci", KERNEL=="0000:03:00.0", DRIVER=="brcmfmac", ATTR{power/wakeup}="disabled"
          #  #SUBSYSTEM=="acpi", KERNEL=="PNP0C0D:00", DRIVER=="button", ATTR{power/wakeup}="disabled" # LID0 in /proc/acpi/wakeup
          #  SUBSYSTEM=="acpi", KERNEL=="PNP0C0D:00", ATTR{power/wakeup}="disabled" # LID0 in /proc/acpi/wakeup
          #'';
          networking.hostName = "MacBookPaul";
          services.net = {
            enable = true;
            mainInt = "wlp3s0";
          };
        })
      ]
      [
        ./home-manager/cmdline.nix
        ./home-manager/desktop.nix
        ./home-manager/desktop-linux.nix
        ./home-manager/rust-stable.nix
      ];

    };
  };
}

