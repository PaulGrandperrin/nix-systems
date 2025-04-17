{pkgs, lib, config, inputs, nixos-flake, home-manager-flake, ...}: {
  imports = [
    ./cmdline.nix
  ];

  nix = {
    registry = rec {
      nixos.flake = nixos-flake;
      #nixos-small.flake = inputs.nixos-small;
      nixos-unstable.flake = inputs.nixos-unstable;
      #nixpkgs-darwin.flake = inputs.nixpkgs-darwin;
      #nur.flake = inputs.nur;
      #flake-utils.flake = inputs.flake-utils;
      #rust-overlay.flake = inputs.rust-overlay;
      home-manager.flake = home-manager-flake;
      nixpkgs.to = { # already set by default for NixOS with nixpkgs.flake.setFlakeRegistry
        type = "path";
        path = (toString pkgs.path);
      };
      n = nixpkgs; # shortcut
      self.flake = inputs.self;
    };
    #registry = lib.mapAttrs (_: value: { flake = value; }) inputs; # nix.generateRegistryFromInputs in flake-utils-plus
    #nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry; # nix.generateNixPathFromInputs in flake-utils-plus # nix.nixPath is not available in HM
  };

  home = {
    packages = with pkgs; [
      (lib.setPrio (-15) unstable.uutils-coreutils-noprefix)
      (lib.hiPrio unstable.uutils-findutils)
      (lib.hiPrio unstable.uutils-diffutils)

      # monitoring
      procs
      wireshark-cli
      smartmontools
      pciutils
      lsof
      nmap
      iperf
      bandwhich
      unstable.bpftop

      # file management
      rsync
      sshfs
      rclone
      nix-du graphviz-nox # nix-du --root /nix/store/*-mutter-git-41.2/|  tred | dot -Tsvg > store.svg
      #nvd # nix store diff-closures
      #yazi # broken # ranger

      # tools
      #jujutsu # git alternative
      parallel
      jq yq fq
      hyperfine
      zip unzip p7zip
      pv
      sd
      httpie curlie xh
      entr
      tmate
      wireguard-tools
      cachix
      yt-dlp # replaces youtube-dl
      ffmpeg
      sops
      ssh-to-age
      grex
      yt-dlp
      nix-inspect
      libtree
      hdparm

      # dev
      gdb
      elfutils
      ruby pry
      #mycli
      pgcli
      gnumake
      gcc11
      (lib.setPrio 20 clang_16)

      # doc
      tealdeer # tldr
      man-pages
      man-pages-posix

      # graphics in term
      viu

      # data recovery
      ddrescue
      testdisk # includes photorec

      # vim distros from my overlay
      (lib.lowPrio ksvim)
      (lib.lowPrio lzvim)
      (lib.lowPrio nvchad)
      (lib.lowPrio aovim)
      (lib.lowPrio lnvim)
      (lib.lowPrio spvim)

      ## use nixvim pkg, but only expose the nvim binary as nixvim
      #(pkgs.runCommandNoCC "nixvim" {} ''
      #  mkdir -p $out/bin
      #  ln -s ${pkgs.nixvim}/bin/nvim $out/bin/nixvim
      #'')

      #((pkgs.writeShellApplication { # hack around https://github.com/NixOS/nix/issues/5810
      #  name = "git";
      #  text = ''
      #    pname="$(ps -o comm= $PPID)"
      #    if [ "$pname" == "nix" ] && [ "$#" -ge 9 ] && [ "$5" == "add" ] && [ "$6" == "--force" ] && [ "$7" == "--intent-to-add" ] && [ "$8" == "--" ] && [ "$9" == "flake.lock" ]; then
      #      exit 0
      #    else
      #      exec -a "$0" "${pkgs.git}/bin/git" "$@" 
      #    fi
      #  '';
      #}).overrideAttrs (final: prev: {
      #  meta.priority = 1;
      #}))

    ] ++ lib.optionals pkgs.stdenv.isLinux [
      lshw
      dstat
      sysstat
      strace
      bmon
      btop
      difftastic # FIXME broken on darwin
      usbutils
      usbtop
      wl-clipboard # used by neovim to yank to clipboard
      trashy
      e2fsprogs

      (buildFHSEnv {
        name = "fhs-run";
        targetPkgs = pkgs: (with pkgs; [
        ]);
        runScript = writeShellScript "fhs-run" ''
          run="$1"
          if [ "$run" = "" ]; then
            echo "Usage: fhs-run command-to-run args..." >&2
            exit 1
          fi
          shift
  
          exec -- "$run" "$@"
        '';
      })

      #nix-alien # or nix-autobahn
      #nix-index
      #nix-index-update

      stress
      hwinfo
      lm_sensors
      mold
      bintools
      distrobox

    ] ++ lib.optionals ((config.home.username == "root") && pkgs.stdenv.isLinux) [ # if root and linux
      bandwhich # iftop
    ] ++ lib.optionals ((config.home.username == "root") && pkgs.stdenv.isLinux) [ # if root and linux
      parted
      powertop
      ethtool
      dmidecode
      bcc
      #mkosi # in 23.11
      tpm2-tools
      ntfs3g
    ] ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
      [ 
        cpuid
        cpufrequtils
        #zenith
        intel-gpu-tools

        nixpkgs-update
        isd
      ] ++ lib.optionals (config.home.username == "root") [ # if root and linux
        i7z
        sbctl # secure boot key manager
        efibootmgr
        efitools
      ]
    );
  };
  programs = {
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
    emacs.enable = true;
    eza = {
      enable = true;
    };
    helix = {
      enable = true;
      package = pkgs.unstable.evil-helix;
      defaultEditor = lib.mkForce true;
      settings = {
        theme = "autumn_night_transparent";
        editor = {
          line-number = "relative";
          lsp.display-messages = true;
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
          #file-picker.hidden = false;
        };
      };
      languages.language = [{
        name = "nix";
        #auto-format = true;
        #formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
      } {
        name = "rust";

      }];
      themes = {
        autumn_night_transparent = {
          "inherits" = "autumn_night";
          "ui.background" = { };
        };
      };
    };
    #fzf = {
    #  enable = true;
    #  tmux.enableShellIntegration = true;
    #};
    nnn.enable = true;
    noti.enable = true;
    nushell.enable = true;
    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
    bottom.enable = true;
    broot.enable = true;
    topgrade.enable = !pkgs.stdenv.isDarwin; # FIXME broken on darwin
    #powerline-go.enable = true;
    #starship = { # async prompt: https://gist.github.com/duament/bac0181935953b97ca71640727c9c029
    #  enable = true;
    #};
    jq.enable = true;
    skim.enable = true;
    rbw = {
      enable = true;
      settings = {
        email = "paul.grandperrin@gmail.com";
        lock_timeout = 300;
        pinentry = pkgs.pinentry.curses;
        device_id = "ea9f961d-c0cc-423c-accf-599fc08c42e0";
      };
    };
    zoxide.enable = true;
    man = {
      enable = true; # by default
      generateCaches = true;
    };
    #mcfly = {
    #  enable = true;
    #  enableFuzzySearch = true;
    #};
    kitty.enable = true;
    wezterm = {
      enable = true;
      package = pkgs.unstable.wezterm;
      extraConfig = ''
        local wezterm = require("wezterm")
        
        local  c = wezterm.config_builder()
        c:set_strict_mode(true)
        c.warn_about_missing_glyphs = false
        
        local act = wezterm.action
        c.keys = {
          {
            key = "-",
            mods = "SHIFT|ALT",
            action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
          },
          {
            key = "=",
            mods = "SHIFT|ALT",
            action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
          },
        }

        --c.color_scheme = 'Catppuccin Mocha'
        c.color_scheme = 'Darkside'
        c.font_size = 14.0

        -- Fix for disapeearing cursor
        -- adapted from https://github.com/wez/wezterm/issues/1742#issuecomment-1075333507
        local xcursor_size = nil
        local xcursor_theme = nil
        
        local success, stdout, stderr = wezterm.run_child_process({"gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"})
        if success then
          xcursor_theme = stdout:gsub("'(.+)'\n", "%1")
        end
        
        local success, stdout, stderr = wezterm.run_child_process({"gsettings", "get", "org.gnome.desktop.interface", "cursor-size"})
        if success then
          xcursor_size = tonumber(stdout)
        end

        c.xcursor_theme = xcursor_theme
        c.xcursor_size = xcursor_size

        c.front_end = "WebGpu"

        c.enable_wayland = false -- work around https://github.com/wez/wezterm/issues/4483
        
        return c
      '';
    };
  };
  
}
