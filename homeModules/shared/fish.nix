args @ {pkgs, lib, ...}: {

  programs.fish = {
    enable = true;
    functions = {
      _tide_item_nix_shell = { # displays nix shell env on the right of the prompt
        body = ''
          # mostly a babelfish conversion of nix-shell-info from any-nix-shell
          # relies on the nix wrapper from any-nix-shell

          if set -q IN_NIX_SHELL || set -q IN_NIX_RUN
            set output (echo $ANY_NIX_SHELL_PKGS | xargs | string collect; or echo)
            if test -n "$name" && test "$name" != 'shell'
              set -a output ' '"$name"
            end
            if test -n "$output"
              set output (echo $output $additional_pkgs | tr ' ' '\\n' | sort -u | tr '\\n' ' ' | xargs | string collect; or echo)
              _tide_print_item nix_shell $tide_nix_shell_icon' ' $output
            else
              _tide_print_item nix_shell $tide_nix_shell_icon' [unknown environment]' 
            end
          end
        '';
      };
    };
    shellInit = ''
      ${lib.optionalString (!args ? osConfig) "source ${pkgs.nix}/etc/profile.d/nix-daemon.fish"}
    '';
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
    + lib.optionalString (args ? darwinConfig) (let
      # fish path: https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1659465635

      # add quotes and remove brackets '${XDG}/foo' => '"$XDG/foo"' 
      dquote = str: "\"" + (builtins.replaceStrings ["{" "}"] ["" ""] str) + "\"";

      makeBinPathList = map (path: path + "/bin");
    in ''
      fish_add_path --move --prepend --path ${lib.concatMapStringsSep " " dquote (makeBinPathList args.darwinConfig.environment.profiles)}
      set fish_user_paths $fish_user_paths
    '');
    shellAliases = {
      icat = "kitty +kitten icat";
    };
    shellAbbrs = {
      ssh-keygen-ed25519 = "ssh-keygen -t ed25519";
      nixos-rebuild-gcp = "nixos-rebuild --flake git+file:///etc/nixos#nixos-gcp --use-substitutes --target-host root@paulg.fr";
      update-hardware-conf = "nixos-generate-config --show-hardware-config --no-filesystems > /etc/nixos/nixosModules/$(hostname)/hardware-configuration.nix && git -C /etc/nixos/ commit /etc/nixos/nixosModules/$(hostname)/hardware-configuration.nix -m \"$(hostname): update hardware-configuration.nix\"";
      nixos-update-flake = "pushd /etc/nixos && nix flake update && git commit -m \"nix flake update\" flake.lock && git push && popd";
      nixos-test = "nixos-rebuild test --flake /etc/nixos/#$(hostname)-lean -L";
      clean-gcroots = "find -L /nix/var/nix/gcroots/per-user/$USER -maxdepth 1 -type l -delete";
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
      #{
      #  name = "pisces"; # pisces # auto pairing of ([{"'
      #  src = pisces.src;
      #}
      {
        name = "plugin-git"; # git abbrs
        #src = plugin-git.src;
        src = pkgs.fetchFromGitHub { # https://github.com/jhillyerd/plugin-git/pull/103 
          owner = "hexclover";
          repo = "plugin-git";
          rev = "master";
          sha256 = "sha256-efKPbsXxjHm1wVWPJCV8teG4DgZN5dshEzX8PWuhKo4";
        };
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
}
