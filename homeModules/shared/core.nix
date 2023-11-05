args @ {pkgs, config, inputs, lib, nixos-flake, home-manager-flake, ...}: {
  imports = [
    ./cmdline.nix
  ];
  xdg.enable = true; # export XDG vars to ensure the correct directories are used
  targets.genericLinux.enable = pkgs.stdenv.isLinux && ! args ? nixosConfig;

  xdg.configFile."nixpkgs/config.nix".source = ../../nixpkgs/config.nix; # read by "nix-shell", "nix shell --impure" etc
  
  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = import ../../nix/nix.nix;

    registry = rec {
      nixos.flake = nixos-flake;
      #nixos-small.flake = inputs.nixos-small;
      nixos-unstable.flake = inputs.nixos-unstable;
      #nixpkgs-darwin.flake = inputs.nixpkgs-darwin;
      #nur.flake = inputs.nur;
      #flake-utils.flake = inputs.flake-utils;
      #rust-overlay.flake = inputs.rust-overlay;
      home-manager.flake = home-manager-flake;
      nixpkgs.to = {
        type = "path";
        path = (toString pkgs.path);
      };
      n = nixpkgs; # shortcut
      paulg.to = {
        type = "path";
        path = (toString ../..);
      };
    };
    #registry = lib.mapAttrs (_: value: { flake = value; }) inputs; # nix.generateRegistryFromInputs in flake-utils-plus
    #nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry; # nix.generateNixPathFromInputs in flake-utils-plus # nix.nixPath is not available in HM
  };

  # systemd.user.systemctlPath = "/usr/bin/systemctl"; # TODO ?
  home = {
    stateVersion = "23.05";
    enableNixpkgsReleaseCheck = true; # check for release version mismatch between Home Manager and Nixpkgs
    sessionVariables = { # only works for interactive shells, pam works for all kind of sessions
      NIX_PATH = (lib.concatStringsSep ":" (lib.mapAttrsToList (name: path: "${name}=${path.to.path}") config.nix.registry));
    };

    # always keep a reference to the source flake that generated each generations
    file.".source-flake".source = ../.;

    packages = with pkgs; [
    ]
    ++ lib.optionals pkgs.stdenv.isLinux (
      [
      ] ++ lib.optionals (config.home.username == "root") [ # if root and linux
      ]
    ) ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
      [ 
      ] ++ lib.optionals (config.home.username == "root") [ # if root and linux
      ]
    );
  };

  # install ssh authorized keys, sshd complains if that's a symlink to the /nix/store
  # only for non-root users
  home.activation = lib.mkIf (config.home.username != "root") (let
    ssh-authorized-keys = pkgs.writeText "ssh-authorized-keys" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVW/7zXgQwIAk46daSBfP5ti7zpADrs1p//f5IyRHJH paulg@darwin-macbook
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE paulg@nixos-gcp
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE root@nixos-gcp
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3KlABFus1z3jTDvylO6e6gSnn7nIqJKZOZJ9di5OW4 paulg@nixos-xps
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2 root@nixos-xps
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBKbOypMYzisA9fwYtZVWWtcvsOqA294EEBIYN/9YCr paulg@nixos-macbook
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57 root@nixos-macbook
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY root@nixos-nas
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSJQGYQs+KJX+V/X3KxhyQgahE0g+ITF2jr1wUY1s/3 paulg@nixos-nas
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvmspiXsIgqF+idEIyEierOJa3m/665LP1U1TkwNx/8 root@nixos-macmini
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLwI5YV8LFCX4MD64uZg6KV5ln+HgMWHR1r/rjVV6T7 paulg@nixos-macmini
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsQJwr21m67xQIUqnHAc4wGkaj6o/Uy002xgN34G8Wj root@nixos-oci
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUV9km+CluTn/QZGOstjxNpPEVkxWktmNrlC8Xqss4F paulg@nixos-oci
  '';
  in {
    copySshAuthorizedKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
     $DRY_RUN_CMD install $VERBOSE_ARG -m700 -d ${config.home.homeDirectory}/.ssh
     $DRY_RUN_CMD install $VERBOSE_ARG -m600 ${ssh-authorized-keys} ${config.home.homeDirectory}/.ssh/authorized_keys
    '';
  });

  services.gpg-agent = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    defaultCacheTtl = 60 * 60 * 24;
    extraConfig = ''
      allow-loopback-pinentry
      max-cache-ttl ${toString (60 * 60 * 24 * 7)}
    '';
  };

}

