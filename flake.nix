{

  description = "Paul Grandperrin NixOS confs";

  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixos-small.url = "github:NixOS/nixpkgs/nixos-21.11-small";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin";
    nixpkgs-darwin-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nur.url = "github:nix-community/NUR";

    nix-on-droid = {
      url = "github:t184256/nix-on-droid";
      inputs.nixpkgs.follows = "nixos";
      inputs.flake-utils.follows = "flake-utils";
      inputs.home-manager.follows = "home-manager";
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

    nixgl = {
      url = "github:guibou/nixGL";
      flake = false;
    };
  };


  outputs = inputs: let 
    stable-pkgs = inputs.nixos.legacyPackages.x86_64-linux;
    unstable-pkgs = inputs.nixos-unstable.legacyPackages.x86_64-linux;
    unstable-overlay = final: prev: { unstable = unstable-pkgs; };
    overlays = [ inputs.nur.overlay inputs.rust-overlay.overlay unstable-overlay];
  in {

    devShell.x86_64-linux = stable-pkgs.mkShell {
        buildInputs = with stable-pkgs; [
          cowsay
          fish
        ];

        shellHook = ''
          cowsay "Welcome"
        '';
      }
    ;

    nixOnDroidConfigurations = {
      pixel6pro = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        system = "aarch64-linux";
        config = {
          home-manager.config = import ./home-manager/cmdline.nix;
	};
        extraModules = [];
      };
    };

    homeConfigurations = let
      system = "x86_64-linux";
    in {
      paulg = inputs.home-manager.lib.homeManagerConfiguration {
        inherit system;
        stateVersion = "21.11";
        homeDirectory = "/home/paulg";
        username = "paulg";
        extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
        configuration = { config, pkgs, lib, ... }: {
          imports = [ ./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix];
          nixpkgs = {inherit overlays;};
          nixpkgs.config.allowUnfree = true;
          home.packages = [
            (pkgs.writeShellScriptBin "nixGLNvidia" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A auto.nixGLNvidia --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixGLIntel" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A nixGLIntel --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixVulkanIntel" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A nixVulkanIntel --no-out-link)/bin/* "$@"'')
            (pkgs.writeShellScriptBin "nixVulkanNvidia" ''$(NIX_PATH=nixpkgs=${inputs.nixos} nix-build ${inputs.nixgl} -A auto.nixVulkanNvidia --no-out-link)/bin/* "$@"'')
          ];
        };  
      };
    };

    darwinConfigurations = let
      system = "x86_64-darwin";
      inputs-darwin = inputs // {nixpkgs = inputs.nixpkgs-darwin;}; # HACK: I don't know a better way to make HM use nixpkgs-darwin...
    in let 
      inputs = inputs-darwin; # HACK: is there a better way to avoid infinite recurtion?
      # redefine those with darwin specific flakes
      stable-pkgs = inputs.nixpkgs-darwin.legacyPackages.x86_64-darwin;
      unstable-pkgs = inputs.nixpkgs-darwin-unstable.legacyPackages.x86_64-darwin;
      unstable-overlay = final: prev: { unstable = unstable-pkgs; };
      overlays = [ inputs.nur.overlay inputs.rust-overlay.overlay unstable-overlay];
    in {
      "MacBookPaul" = inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [
          { 
            nixpkgs = {inherit overlays;};
            nixpkgs.config.allowUnfree = true;
            nix.registry.n.flake = inputs.nixpkgs-darwin; # to easily try out packages: nix shell nix#htop
          }
          ./nix-darwin/common.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
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
            nixpkgs = {inherit overlays;};
            nixpkgs.config.allowUnfree = true;
            nix.registry.n.flake = inputs.nixpkgs-darwin; # to easily try out packages: nix shell nix#htop
          }
          ./nix-darwin/common.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
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
      nixos-nas = inputs.nixos-small.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {inherit overlays; }; }
          ./nixos/hosts/nas/hardware-configuration.nix
          ./nixos/common.nix
          ./nixos/nspawns/debian.nix
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
            nix.registry.n.flake = inputs.nixos-small; # to easily try out packages: nix shell nix#htop
          }
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix];};
          }
        ];
      };

      nixos-gcp = inputs.nixos-small.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {inherit overlays; }; }
          ./nixos/hosts/gcp/hardware-configuration.nix
          ./nixos/google-compute-config.nix
          ./nixos/common.nix
          ./nixos/containers/web.nix
          # ./nixos/auto-upgrade.nix # 1G of memory is not enough to evaluate the system's derivation, even with zram...
          ({pkgs, ...}:{
            networking.hostId = "1c734661"; # for ZFS
            networking.hostName = "nixos-gcp";
            networking.interfaces.eth0.useDHCP = true;
            
            # useful to build and deploy closures from nixos-xps which a lot beefier than nixos-gcp
            users.users.root.openssh.authorizedKeys.keys = [ 
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2" # root@nixos-xps
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57" # root@MacBookPaul NixOS
            ];
            
            system.stateVersion = "21.05"; # Did you read the comment?
          
            environment.systemPackages = with pkgs; [
              google-cloud-sdk-gce
            ];
            nix.registry.n.flake = inputs.nixos-small; # to easily try out packages: nix shell nix#htop
          })
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = false;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix];};
          }
        ];
      };

      nixos-xps = inputs.nixos.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {inherit overlays; }; }
          ./nixos/hosts/xps/hardware-configuration.nix
          ./nixos/common.nix
          ./nixos/net.nix
          ./nixos/laptop.nix
          ./nixos/desktop.nix
          ./nixos/desktop-i915.nix
          ./nixos/desktop-nvidia-prime.nix
          {
            networking.hostId="7ee1da4a";
            system.stateVersion = "21.11"; # Did you read the comment?
            networking.hostName = "nixos-xps";
            services.net = {
              enable = true;
              mainInt = "wlp2s0";
            };
            nix.registry.n.flake = inputs.nixos; # to easily try out packages: nix shell nix#htop
          }
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = true;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/desktop-linux.nix ./home-manager/rust-nightly.nix];};
          }
        ];
      };


      MacBookPaul = inputs.nixos.lib.nixosSystem { # not defined in the lib... but in Nixpkgs/flake.nix !
        inherit system;
        specialArgs = { inherit system inputs; }; #  passes inputs to modules
        modules = [ 
          { nixpkgs = {inherit overlays; }; }
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
            nix.registry.n.flake = inputs.nixos; # to easily try out packages: nix shell nix#htop
          })
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit system inputs; installDesktopApp = true;};
            home-manager.users.root  = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-root.nix];};
            home-manager.users.paulg = { imports = [./home-manager/cmdline.nix ./home-manager/cmdline-user.nix ./home-manager/desktop.nix ./home-manager/desktop-linux.nix ./home-manager/rust-nightly.nix];};
          }
        ];
      };

    };
  };
}

