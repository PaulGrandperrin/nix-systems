{pkgs, config, inputs, ...}: {
  imports = [
    ./cmdline.nix
  ];


  home = {
    packages = with pkgs; [
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
      jujutsu # git alternative
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
    helix.enable = true;
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
        
        return c
      '';
    };
  };
  
}
