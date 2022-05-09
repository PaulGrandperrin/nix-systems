{

  description = "Paul Grandperrin NixOS confs";

  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixos-small.url = "github:NixOS/nixpkgs/nixos-21.11-small";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin";
    nixpkgs-darwin-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nur.url = "github:nix-community/NUR";

    nix-on-droid = {
      url = "github:t184256/nix-on-droid/testing";
      inputs.nixpkgs.follows = "nixos-unstable";
      inputs.flake-utils.follows = "flake-utils";
      inputs.home-manager.follows = "home-manager-unstable";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixos";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixos-unstable";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixos";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixos";
    };

    nixgl = {
      url = "github:guibou/nixGL";
      flake = false;
    };
  };


  outputs = inputs: let 
    getOverlays = system: let # FIXME not sure those are the good channels for darwin
      stable-pkgs = inputs.nixos.legacyPackages.${system};
      unstable-pkgs = inputs.nixos-unstable.legacyPackages.${system};
      unstable-overlay = final: prev: { unstable = unstable-pkgs; };
    in
      [ inputs.nur.overlay inputs.rust-overlay.overlay unstable-overlay inputs.nix-alien.overlay];
  in {

    packages.x86_64-linux.vcv-rack = inputs.nixos.legacyPackages.x86_64-linux.callPackage ./pkgs/vcv-rack {};

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
            extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nix-on-droid.inputs.nixpkgs; installDesktopApp = false;};
            config = {pkgs, lib, config, ...}: {
              imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix];
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
      paulg-x86_64-linux = inputs.home-manager.lib.homeManagerConfiguration rec {
        system = "x86_64-linux";
        stateVersion = "21.11";
        homeDirectory = "/home/paulg";
        username = "paulg";
        extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixos-21.11; installDesktopApp = false;};
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix];
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
      paulg-aarch64-darwin = inputs.home-manager.lib.homeManagerConfiguration rec {
        system = "aarch64-darwin";
        stateVersion = "21.11";
        homeDirectory = "/Users/paulg";
        username = "paulg";
        extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixos-21.11; installDesktopApp = false;};
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/desktop-macos.nix];
          nixpkgs.overlays = getOverlays system;
          nixpkgs.config.allowUnfree = true;
        };  
      };
    };

    darwinConfigurations = let
      system = "x86_64-darwin";
      inputs-darwin = inputs // {nixpkgs = inputs.nixpkgs-darwin;}; # HACK: I don't know a better way to make HM use nixpkgs-darwin...
    in let 
      inputs = inputs-darwin; # HACK: is there a better way to avoid infinite recurtion?
    in {
      "MacBookPaul" = inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [
          { 
            nixpkgs = {overlays = getOverlays system;};
            nixpkgs.config.allowUnfree = true;
          }
          ./nix-darwin/common.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixpkgs-darwin; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/desktop-macos.nix ./home-manager/rust-stable.nix];};
          }
        ];
      };

      "MacMiniPaul" = inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [
          { 
            nixpkgs = {overlays = getOverlays system;};
            nixpkgs.config.allowUnfree = true;
          }
          ./nix-darwin/common.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixpkgs-darwin; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/desktop-macos.nix];};
          }
        ];
      };
    };

    # Used with `nixos-rebuild --flake .#<hostname>`
    # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
    nixosConfigurations = let
        system = "x86_64-linux";
    in { 
      nixos-nas = inputs.nixos-unstable-small.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {overlays = getOverlays system; }; }
          ./nixos/hosts/nas/hardware-configuration.nix
          ./nixos/common.nix
          ./nixos/nspawns/ubuntu.nix
          ./nixos/net.nix
          ./nixos/auto-upgrade.nix
          {
            networking.hostId="51079489";
            system.stateVersion = "21.05"; # Did you read the comment?
            networking.hostName = "nixos-nas";
            services.net = {
              enable = true;
              mainInt = "enp3s0";
            }; 
          }
          inputs.home-manager-unstable.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs;  mainFlake = inputs.nixos-unstable-small; installDesktopApp = false; is_unstable = true;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix];};
          }
          inputs.nix-ld.nixosModules.nix-ld
        ];
      };

      nixos-gcp = inputs.nixos-small.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {overlays = getOverlays system; }; }
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

            system.stateVersion = "21.05"; # Did you read the comment?
          
            environment.systemPackages = with pkgs; [
              google-cloud-sdk-gce
            ];
          })
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixos-small; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix];};
          }
          inputs.nix-ld.nixosModules.nix-ld
        ];
      };

      nixos-xps = inputs.nixos-unstable.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {overlays = getOverlays system; }; }
          ./nixos/hosts/xps/hardware-configuration.nix
          ./nixos/common.nix
          ./nixos/net.nix
          ./nixos/laptop.nix
          ./nixos/desktop.nix
          ./nixos/desktop-i915.nix
          ./nixos/nvidia.nix
          {
            networking.hostId="7ee1da4a";
            system.stateVersion = "21.11"; # Did you read the comment?
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
          inputs.home-manager-unstable.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; mainFlake = inputs.nixos-unstable; installDesktopApp = true; is_unstable = true;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/desktop-linux.nix ./home-manager/rust-nightly.nix];};
          }
          inputs.nix-ld.nixosModules.nix-ld
        ];
      };


      MacBookPaul = inputs.nixos-unstable.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {overlays = getOverlays system; }; }
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
            system.stateVersion = "21.11"; # Did you read the comment?
            networking.hostName = "MacBookPaul";
            services.net = {
              enable = true;
              mainInt = "wlp3s0";
            };
          })
          inputs.home-manager-unstable.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs;  mainFlake = inputs.nixos-unstable; installDesktopApp = true; is_unstable = true;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/desktop-linux.nix ./home-manager/rust-stable.nix];};
          }
        ];
      };

    };
  };
}

