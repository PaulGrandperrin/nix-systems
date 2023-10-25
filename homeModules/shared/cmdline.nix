args @ {pkgs, config, osConfig ? null, inputs, lib, ...}: {
  imports = [
    inputs.nix-index-database.hmModules.nix-index
  ];

  home = {
    sessionVariables = { # only works for interactive shells, pam works for all kind of sessions
      EDITOR = "vim";
    };

    packages = with pkgs; [
      config.nix.package

      # from https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/system-path.nix
      # acl # linux only
      # attr # linux only
      bashInteractive # bash with ncurses support
      bzip2
      (lib.hiPrio coreutils-full)
      cpio
      curl
      diffutils
      findutils
      gawk
      stdenv.cc.libc
      getent
      getconf
      gnugrep
      gnupatch
      gnused
      gnutar
      gzip
      xz
      less
      # libcap # linux only
      ncurses
      netcat
      openssh # config.programs.ssh.package 
      mkpasswd
      procps
      #su # only useful with suid
      time
      util-linux
      which
      zstd

      # vim distros from my overlay
      ksvim
      lzvim
      nvchad
      aovim
      lnvim
      spvim

      rsync
      unstable.nixd
      socat
      whois
      parallel
      util-linux # unshare nsenter
      sshfs
      rclone

      gdb
      elfutils

      fd
      tree
      ncdu
      wget
      ripgrep
      pstree
      file
      #nvd # nix store diff-closures
      killall # psmisc, toybox?
      hostname
      nix-du graphviz-nox
      jq yq
      ruby pry
      #mycli
      tldr
      hyperfine
      ranger
      cachix
      manix
      neofetch
      unzip p7zip
      pv
      duf
      wireshark-cli
      youtube-dl
      ffmpeg
      gdu
      pgcli
      sd
      httpie curlie xh
      entr
      tig
      choose
      tmate
      du-dust
      fq
      smartmontools
      wireguard-tools
      dogdns
      wakelan
      pciutils
      lsof
      nmap
      iperf

      sops
      ssh-to-age

      #man
      man-pages
      man-pages-posix

      # graphics in term
      viu

      #dev
      gnumake
      gcc11
      (lib.setPrio 20 clang_16)
      rnix-lsp

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
    ]
    ++ lib.optionals pkgs.stdenv.isLinux (
      [
        lshw
        dstat
        sysstat
        strace
        bmon
        btop
        difftastic # FIXME broken on darwin
        lsb-release
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

        #unstable.nix
        #unstable.nixos-rebuild

        stress
        hwinfo
        lm_sensors
        mold
        bintools
        distrobox
      ] ++ lib.optionals (config.home.username == "root") [ # if root and linux
        parted
        iftop
        powertop
        ethtool
        dmidecode
        bcc
        #mkosi # in 23.11
        tpm2-tools
        ntfs3g
      ]
    ) ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
      [ 
        cpuid
        cpufrequtils
        zenith
        intel-gpu-tools
      ] ++ lib.optionals (config.home.username == "root") [ # if root and linux
        i7z
        sbctl # secure boot key manager
        efibootmgr
        efitools
      ]
    );
  };

  programs = {
    home-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
    nix-index-database.comma.enable = true;
    emacs.enable = true;
    exa = {
      enable = true;
      enableAliases = false;
    };
    lsd = {
      enable = true;
      enableAliases = true;
    };
    bat.enable = true;
    helix.enable = true;
    htop.enable = true;
    #fzf = {
    #  enable = true;
    #  tmux.enableShellIntegration = true;
    #  package = pkgs.fzf.overrideAttrs (final: prev: {
    #    postInstall = (prev.postInstall or "") + ''
    #      cat << EOF > $out/share/fish/vendor_conf.d/load-fzf-key-bindings.fish
    #        status is-interactive; or exit 0
    #        fzf_key_bindings
    #      EOF
    #    '';
    #  });
    #};
    gh.enable = true;
    nnn.enable = true;
    noti.enable = true;
    nushell.enable = true;
    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
    bottom.enable = true;
    broot.enable = true;
    tmux = {
      enable = true;
      plugins = with pkgs; [
        tmuxPlugins.cpu
    #    {
    #      plugin = tmuxPlugins.resurrect;
    #      extraConfig = "set -g @resurrect-strategy-nvim 'session'";
    #    }
    #    {
    #      plugin = tmuxPlugins.continuum;
    #      extraConfig = ''
    #        set -g @continuum-boot 'on'
    #        set -g @continuum-restore 'on'
    #        set -g @continuum-save-interval '5' # minutes
    #      '';
    #    }
      ];
    };
    topgrade.enable = !pkgs.stdenv.isDarwin; # FIXME broken on darwin
    gpg = {
      enable = true;
      settings = {
        pinentry-mode = "loopback";
      };
    };
    jq.enable = true;
    lazygit.enable = true;
    skim.enable = true;
    rbw = {
      enable = true;
      settings = {
        email = "paul.grandperrin@gmail.com";
        lock_timeout = 300;
        pinentry = "curses";
        device_id = "ea9f961d-c0cc-423c-accf-599fc08c42e0";
      };
    };
    zoxide.enable = true;
    #powerline-go.enable = true;
    #starship = { # async prompt: https://gist.github.com/duament/bac0181935953b97ca71640727c9c029
    #  enable = true;
    #};
    man = {
      enable = true; # by default
      generateCaches = true;
    };
    #mcfly = {
    #  enable = true;
    #  enableFuzzySearch = true;
    #};
    neovim =  {
      enable = true;
      #package = pkgs.unstable.neovim-unwrapped;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins =  with pkgs.vimPlugins;  [
        vim-surround # Shortcuts for setting () {} etc.
        vim-nix # nix highlight
        neovim-fuzzy # fuzzy finder through vim
        vim-lastplace # restore cursor position
        # LSP
        pkgs.unstable.vimPlugins.nvim-lspconfig
        #pkgs.unstable.vimPlugins.lsp-zero-nvim
        (
          pkgs.vimUtils.buildVimPluginFrom2Nix {
            pname = "lsp-zero.nvim";
            version = "2023-09-23";
            src = pkgs.fetchFromGitHub {
              owner = "VonHeikemen";
              repo = "lsp-zero.nvim";
              rev = "011edd4afede7030cb17248495063ab8f3bd0e57";
              sha256 = "sha256-AW9QVBjvnxVcAvS1IUivra+B+8hHBfJyy/vIY1TszQs=";
            };
            meta.homepage = "https://github.com/VonHeikemen/lsp-zero.nvim/";
          }
        )
        # autocomplete
        pkgs.unstable.vimPlugins.nvim-cmp
        pkgs.unstable.vimPlugins.cmp-buffer
        pkgs.unstable.vimPlugins.cmp-path
        pkgs.unstable.vimPlugins.cmp_luasnip
        pkgs.unstable.vimPlugins.cmp-nvim-lsp
        pkgs.unstable.vimPlugins.cmp-nvim-lua
        # snippets
        pkgs.unstable.vimPlugins.luasnip
        pkgs.unstable.vimPlugins.friendly-snippets
      ];
      extraConfig = ''
      '';
      extraLuaConfig = ''
        vim.opt.undofile = true -- saves to $XDG_STATE_HOME/nvim/undo
        -- set.undolevels = 1000
        -- set.undoreload = 10000

        vim.cmd("set mouse=")
        -- reserve space for diagnostic icons
        vim.opt.signcolumn = 'yes'

        local lsp = require('lsp-zero').preset({
          name = 'system-lsp',
          set_lsp_keymaps = true,
          manage_nvim_cmp = true,
        })

        lsp.configure('rust_analyzer', {
        force_setup = true, -- skip checks because it's installed globally
          on_attach = function(client, bufnr)
            print('hello rust')
          end
        })

        lsp.configure('nixd', {
        force_setup = true, -- skip checks because it's installed globally
          on_attach = function(client, bufnr)
          end
        })
  
        lsp.setup()
      '';
    };
    git = {
      enable = true;
      userName = "Paul Grandperrin";
      userEmail = "paul.grandperrin@gmail.com";
      delta = {
        enable = true;
        options = {
          navigate = true;
          line-numbers = true;
          syntax-theme = "Dracula";
        };
      };
      difftastic = {
        #enable = true;
        background = "dark";
        #display = "side-by-side"; # "side-by-side", "side-by-side-show-both", "inline"
      };
      extraConfig = {
        init.defaultBranch = "main";
        pull.ff = "only";
        merge.conflictstyle = "diff3";
      };
      signing = {
        key = "4AB1353033774DA3";
      };
      lfs = {
        enable = true;
        skipSmudge = true;
      };
    };
    kitty.enable = true;
    wezterm = {
      enable = true;
      package = pkgs.unstable.wezterm;
      extraConfig = ''
        local wezterm = require("wezterm")
        
        local  c = wezterm.config_builder()
        c:set_strict_mode(true)
        
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
        
        return c
      '';
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g theme_nerd_fonts yes
        set -g fish_greeting
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source # use fish in nix run and nix-shell
        source ${
          pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/gnachman/iTerm2/c52136b7c0bae545436be8d1441449f19e21faa1/Resources/shell_integration/iterm2_shell_integration.fish";
            sha256 = "sha256-l7KdmiJlbGy/ozC+l5rrmEebA8kZgV7quYG5I/MHDOI=";
          }
        }
        #tide configure --auto --style=Classic --prompt_colors='True color' --classic_prompt_color=Darkest --show_time='24-hour format' --classic_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='One line' --prompt_spacing=Compact --icons='Many icons' --transient=No
        set -U tide_aws_bg_color 1C1C1C
        set -U tide_aws_color FF9900
        set -U tide_aws_icon \uf270
        set -U tide_character_color 5FD700
        set -U tide_character_color_failure FF0000
        set -U tide_character_icon \u276f
        set -U tide_character_vi_icon_default \u276e
        set -U tide_character_vi_icon_replace \u25b6
        set -U tide_character_vi_icon_visual V
        set -U tide_cmd_duration_bg_color 1C1C1C
        set -U tide_cmd_duration_color 87875F
        set -U tide_cmd_duration_decimals 0
        set -U tide_cmd_duration_icon \uf252
        set -U tide_cmd_duration_threshold 3000
        set -U tide_context_always_display false
        set -U tide_context_bg_color 1C1C1C
        set -U tide_context_color_default D7AF87
        set -U tide_context_color_root D7AF00
        set -U tide_context_color_ssh D7AF87
        set -U tide_context_hostname_parts 1
        set -U tide_crystal_bg_color 1C1C1C
        set -U tide_crystal_color FFFFFF
        set -U tide_crystal_icon \ue62f
        set -U tide_direnv_bg_color 1C1C1C
        set -U tide_direnv_bg_color_denied 1C1C1C
        set -U tide_direnv_color D7AF00
        set -U tide_direnv_color_denied FF0000
        set -U tide_direnv_icon \u25bc
        set -U tide_distrobox_bg_color 1C1C1C
        set -U tide_distrobox_color FF00FF
        set -U tide_distrobox_icon \U000f01a7
        set -U tide_docker_bg_color 1C1C1C
        set -U tide_docker_color 2496ED
        set -U tide_docker_default_contexts default\x1ecolima
        set -U tide_docker_icon \uf308
        set -U tide_elixir_bg_color 1C1C1C
        set -U tide_elixir_color 4E2A8E
        set -U tide_elixir_icon \ue62d
        set -U tide_gcloud_bg_color 1C1C1C
        set -U tide_gcloud_color 4285F4
        set -U tide_gcloud_icon \U000f02ad
        set -U tide_git_bg_color 1C1C1C
        set -U tide_git_bg_color_unstable 1C1C1C
        set -U tide_git_bg_color_urgent 1C1C1C
        set -U tide_git_color_branch 5FD700
        set -U tide_git_color_conflicted FF0000
        set -U tide_git_color_dirty D7AF00
        set -U tide_git_color_operation FF0000
        set -U tide_git_color_staged D7AF00
        set -U tide_git_color_stash 5FD700
        set -U tide_git_color_untracked 00AFFF
        set -U tide_git_color_upstream 5FD700
        set -U tide_git_icon \uf1d3
        set -U tide_git_truncation_length 24
        set -U tide_git_truncation_strategy \x1d
        set -U tide_go_bg_color 1C1C1C
        set -U tide_go_color 00ACD7
        set -U tide_go_icon \ue627
        set -U tide_java_bg_color 1C1C1C
        set -U tide_java_color ED8B00
        set -U tide_java_icon \ue256
        set -U tide_jobs_bg_color 1C1C1C
        set -U tide_jobs_color 5FAF00
        set -U tide_jobs_icon \uf013
        set -U tide_kubectl_bg_color 1C1C1C
        set -U tide_kubectl_color 326CE5
        set -U tide_kubectl_icon \U000f10fe
        set -U tide_left_prompt_frame_enabled false
        set -U tide_left_prompt_items vi_mode\x1eos\x1epwd\x1egit
        set -U tide_left_prompt_prefix 
        set -U tide_left_prompt_separator_diff_color \ue0b0
        set -U tide_left_prompt_separator_same_color \ue0b1
        set -U tide_left_prompt_suffix \ue0b0
        set -U tide_nix_shell_bg_color 1C1C1C
        set -U tide_nix_shell_color 7EBAE4
        set -U tide_nix_shell_icon \uf313
        set -U tide_node_bg_color 1C1C1C
        set -U tide_node_color 44883E
        set -U tide_node_icon \ue24f
        set -U tide_os_bg_color 1C1C1C
        set -U tide_os_color EEEEEE
        set -U tide_os_icon \uf313
        set -U tide_php_bg_color 1C1C1C
        set -U tide_php_color 617CBE
        set -U tide_php_icon \ue608
        set -U tide_private_mode_bg_color 1C1C1C
        set -U tide_private_mode_color FFFFFF
        set -U tide_private_mode_icon \U000f05f9
        set -U tide_prompt_add_newline_before false
        set -U tide_prompt_color_frame_and_connection 6C6C6C
        set -U tide_prompt_color_separator_same_color 949494
        set -U tide_prompt_icon_connection \x20
        set -U tide_prompt_min_cols 34
        set -U tide_prompt_pad_items true
        set -U tide_prompt_transient_enabled false
        set -U tide_pulumi_bg_color 1C1C1C
        set -U tide_pulumi_color F7BF2A
        set -U tide_pulumi_icon \uf1b2
        set -U tide_pwd_bg_color 1C1C1C
        set -U tide_pwd_color_anchors 00AFFF
        set -U tide_pwd_color_dirs 0087AF
        set -U tide_pwd_color_truncated_dirs 8787AF
        set -U tide_pwd_icon \uf07c
        set -U tide_pwd_icon_home \uf015
        set -U tide_pwd_icon_unwritable \uf023
        set -U tide_pwd_markers \x2ebzr\x1e\x2ecitc\x1e\x2egit\x1e\x2ehg\x1e\x2enode\x2dversion\x1e\x2epython\x2dversion\x1e\x2eruby\x2dversion\x1e\x2eshorten_folder_marker\x1e\x2esvn\x1e\x2eterraform\x1eCargo\x2etoml\x1ecomposer\x2ejson\x1eCVS\x1ego\x2emod\x1epackage\x2ejson
        set -U tide_python_bg_color 1C1C1C
        set -U tide_python_color 00AFAF
        set -U tide_python_icon \U000f0320
        set -U tide_right_prompt_frame_enabled false
        set -U tide_right_prompt_items status\x1ecmd_duration\x1econtext\x1ejobs\x1edirenv\x1enode\x1epython\x1erustc\x1ejava\x1ephp\x1epulumi\x1eruby\x1ego\x1egcloud\x1ekubectl\x1edistrobox\x1etoolbox\x1eterraform\x1eaws\x1enix_shell\x1ecrystal\x1eelixir\x1etime
        set -U tide_right_prompt_prefix \ue0b2
        set -U tide_right_prompt_separator_diff_color \ue0b2
        set -U tide_right_prompt_separator_same_color \ue0b3
        set -U tide_right_prompt_suffix 
        set -U tide_ruby_bg_color 1C1C1C
        set -U tide_ruby_color B31209
        set -U tide_ruby_icon \ue23e
        set -U tide_rustc_bg_color 1C1C1C
        set -U tide_rustc_color F74C00
        set -U tide_rustc_icon \ue7a8
        set -U tide_shlvl_bg_color 1C1C1C
        set -U tide_shlvl_color d78700
        set -U tide_shlvl_icon \uf120
        set -U tide_shlvl_threshold 1
        set -U tide_status_bg_color 1C1C1C
        set -U tide_status_bg_color_failure 1C1C1C
        set -U tide_status_color 5FAF00
        set -U tide_status_color_failure D70000
        set -U tide_status_icon \u2714
        set -U tide_status_icon_failure \u2718
        set -U tide_terraform_bg_color 1C1C1C
        set -U tide_terraform_color 844FBA
        set -U tide_terraform_icon \x1d
        set -U tide_time_bg_color 1C1C1C
        set -U tide_time_color 5F8787
        set -U tide_time_format \x25T
        set -U tide_toolbox_bg_color 1C1C1C
        set -U tide_toolbox_color 613583
        set -U tide_toolbox_icon \ue24f
        set -U tide_vi_mode_bg_color_default 1C1C1C
        set -U tide_vi_mode_bg_color_insert 1C1C1C
        set -U tide_vi_mode_bg_color_replace 1C1C1C
        set -U tide_vi_mode_bg_color_visual 1C1C1C
        set -U tide_vi_mode_color_default 949494
        set -U tide_vi_mode_color_insert 87AFAF
        set -U tide_vi_mode_color_replace 87AF87
        set -U tide_vi_mode_color_visual FF8700
        set -U tide_vi_mode_icon_default D
        set -U tide_vi_mode_icon_insert I
        set -U tide_vi_mode_icon_replace R
        set -U tide_vi_mode_icon_visual V
      '';
      loginShellInit = ''
      ''
      + lib.optionalString (pkgs.stdenv.isDarwin && ! builtins.isNull osConfig) (let
        # fish path: https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1659465635

        # add quotes and remove brackets '${XDG}/foo' => '"$XDG/foo"' 
        dquote = str: "\"" + (builtins.replaceStrings ["{" "}"] ["" ""] str) + "\"";

        makeBinPathList = map (path: path + "/bin");
      in ''
        fish_add_path --move --prepend --path ${lib.concatMapStringsSep " " dquote (makeBinPathList osConfig.environment.profiles)}
        set fish_user_paths $fish_user_paths
      '');
      shellAliases = {
        icat = "kitty +kitten icat";
      };
      shellAbbrs = {
        ssh-keygen-ed25519 = "ssh-keygen -t ed25519";
        nixos-rebuild-gcp = "nixos-rebuild --flake git+file:///etc/nixos#nixos-gcp --use-substitutes --target-host root@paulg.fr";
        update-hardware-conf = "nixos-generate-config --show-hardware-config --no-filesystems > /etc/nixos/nixosModules/$(hostname)/hardware-configuration.nix && git -C /etc/nixos/ commit /etc/nixos/nixosModules/$(hostname)/hardware-configuration.nix -m \"$(hostname): update hardware-configuration.nix\"";
        update-nixos-flake = "pushd /etc/nixos && nix flake update && git commit -m \"nix flake update\" flake.lock && git push && popd";
      };
      plugins = with pkgs.fishPlugins; [

        ### PROMPTS

        {
          name = "tide"; # natively async
          #src = tide.src; # 5.6 on 23.11
          src = pkgs.fetchFromGitHub {
            owner = "IlanCosman";
            repo = "tide";
            rev = "v6.0.1";
            sha256 = "sha256-oLD7gYFCIeIzBeAW1j62z5FnzWAp3xSfxxe7kBtTLgA=";
          };
        }
        #{
        #  name = "bobthefish"; # need async-prompt to be async
        #  src = bobthefish.src;
        #}
        #{
        #  name = "hydro"; # natively async
        #  src = hydro.src;
        #}
        #{
        #  name = "pure"; # need async-prompt to be async
        #  src = pure.src;
        #}

        ### PLUGINS

        {
          name = "puffer"; # adds "...", "!!" and "!$"
          src = puffer.src;
        }
        {
          name = "pisces"; # pisces # auto pairing of ([{"'
          src = pisces.src;
        }
        {
          name = "plugin-git"; # git abbrs
          src = plugin-git.src;
        }
        #{
        #  name = "done"; # doesn't work on wayland
        #  src = done.src;
        #}
        #{
        #  name = "async-prompt"; # pisces # auto pairing of ([{"'
        #  src = async-prompt.src;
        #}
      ];
    };
  };
}

