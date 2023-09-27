{pkgs, inputs, lib, config, system, ...}: lib.mkIf (config.home.username != "root") {
  targets.genericLinux.enable = true;
  home = {
    packages = with pkgs; [
      gnome.gnome-tweaks

      #gnomeExtensions.sound-output-device-chooser # incomp
      gnomeExtensions.bluetooth-quick-connect
      #gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      #gnomeExtensions.pixel-saver # incomp
      #gnomeExtensions.floating-dock # incomp
      gnomeExtensions.emoji-selector
      gnomeExtensions.clipboard-indicator
      #gnomeExtensions.drop-down-terminal # incomp
      #gnomeExtensions.ddterm
      #gnomeExtensions.coverflow-alt-tab
      gnomeExtensions.dash-to-dock # well maintained
      #gnomeExtensions.dash-to-panel # unmaintained
      #gnomeExtensions.dock-from-dash # little maintained
      gnomeExtensions.caffeine
      gnomeExtensions.appindicator
      gnomeExtensions.bluetooth-battery
      gnomeExtensions.task-widget
      gnomeExtensions.focus-indicator
      #gnomeExtensions.desktop-cube
      #gnomeExtensions.pop-shell

      unstable.gnomeExtensions.system76-scheduler
      #wintile?

      # nix run --impure --expr '(builtins.getFlake "n").legacyPackages.x86_64-linux.blender.override {cudaSupport = true;}'

      glxinfo
      vulkan-tools
      libva-utils # vainfo
      vdpauinfo
      ffmpeg
      mpv
      vlc
      waydroid
      gimp
      easyeffects
      (symlinkJoin {
        name = "signal-desktop";
        paths = [ (callPackage (inputs.nixos-unstable.outPath + "/pkgs/applications/networking/instant-messengers/signal-desktop") {}).signal-desktop ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/signal-desktop \
            --set-default NIXOS_OZONE_WL 1
        '';
      })
      discord
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
      deluge
      rawtherapee
      libreoffice
      gnome.dconf-editor
      helvum
      gnome-console
      popcorntime

      ( let my-kodi = 
          kodi-wayland.withPackages (kodiPkgs: with kodiPkgs; [
            #youtube
            libretro
            libretro-snes9x
            #osmc-skin
            arteplussept
            steam-library
            steam-launcher
	]); in 
        buildFHSUserEnvBubblewrap {
          name = "kodi";
          targetPkgs = pkgs: (with pkgs; [
          ]);
          runScript = "${my-kodi}/bin/kodi";
        }
      )

      #(callPackage ../pkgs/vcv-rack {})

      # I want protonvpn from unstable but I don't want to pull its dependencies from unstable
      #(callPackage (inputs.nixos-unstable.outPath + "/pkgs/applications/networking/protonvpn-gui") {
      #  python3Packages = ( python3Packages // {protonvpn-nm-lib = python3Packages.callPackage (inputs.nixos-unstable.outPath + "/pkgs/development/python-modules/protonvpn-nm-lib") {};});
      #})
    ];
    sessionVariables = { # only works for interactive shells
    };

  };

  # nixgl or hardware.opengl.setLdLibraryPath = true;

  dconf.settings = {
    "org/gnome/calculator" = {
      button-mode = "programming";
    };
    "org/gnome/desktop/notifications" = {
      show-in-lock-screen = false;
    };
    "org/gnome/desktop/interface" = {
      show-battery-percentage = true;
      clock-show-weekday = true;
    };
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" "rt-scheduler" ];
    };
    "org/gnome/desktop/privacy" = {
      remember-recent-files = true;
      recent-files-max-age = 7;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
      old-files-age = 30;
    };
    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = true;
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
    };
    "org/gnome/desktop/input-sources" = {
      xkb-options = 
        ["terminate:ctrl_alt_bksp" "compose:ralt" "lv3:switch" "eurosign:e"];
    };
    "org/gnome/desktop/media-handling" = {
      autorun-never = true;
      automount = false;
      automount-open = false;
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      delay = 500;
      repeat-interval = 30;
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "terminator.desktop"
        "org.gnome.Nautilus.desktop"
        "code.desktop"
        "signal-desktop.desktop"
      ];
      enabled-extensions = (map (extension: extension.extensionUuid) (builtins.filter (x: x ? extensionUuid) config.home.packages)) ++ [
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
      ];
    };
    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = false; # false isn't taken into account...
      idle-brightness = 100; # 100 means that it stay at whatever is was before
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "suspend";
      sleep-inactive-battery-timeout = 300; # time to sleep on battery 
      power-saver-profile-on-low-battery = true;
      power-button-action = "suspend";
    };
    "org/gnome/desktop/session" = {
      idle-delay = 120; # time to blank screen
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = 0;
    };
    "org/gnome/system/location" = {
      enabled = true;
    };
    "org/gnome/shell/weather" = {
      automatic-location = true;
    };
    "org/gnome/desktop/datetime" = {
      automatic-timezone = true;
    };
  };

  #xdg.configFile."wireplumber/default-profile".text = ''
  #  [default-profile]
  #  bluez_card.60_AB_D2_23_56_13=a2dp-sink-sbc_xq
  #'';


  xdg.configFile = {
    "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
      bluez_monitor.properties = {
        ["bluez5.enable-sbc-xq"] = true,
        ["bluez5.enable-msbc"] = true,
        ["bluez5.enable-hw-volume"] = true,
        ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]",
      }
    '';
    "wireplumber/bluetooth.lua.d/51-bluez-bose700-sbc_xq.lua".text = ''
      rule = {
        matches = {
          {
            { "node.name", "equals", "bluez_output.60_AB_D2_23_56_13.a2dp-sink" },
          },
        },                                                                                                                                                                                   
        apply_properties = {
          ["api.bluez5.codec"] = "sbc_xq", -- force SBC_XQ or else AAC is choosen
        },
      }
      table.insert(bluez_monitor.rules,rule)
    '';
  };

  systemd.user.sessionVariables = {
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = {
      package = pkgs.adwaita-qt;
      name = "adwaita";
    };
  };

  services = {
    #flameshot.enable = true; #TODO
  };

  programs = {
    foot.enable = true;
    kitty.enable = true; 
    alacritty.enable = true;
    mangohud.enable = true;
    vscode = { # better than plain package which can't install extensions from internet
      enable = true;
      package = let
        vscode = pkgs.callPackage (inputs.nixos-unstable.outPath + "/pkgs/applications/editors/vscode/vscode.nix") {
          # the asar package has changed name in 23.11
          callPackage = p: overrides: pkgs.callPackage p (overrides // {asar = pkgs.nodePackages.asar;});
        };
        vscode-fhsWithPackages = vscode.fhsWithPackages;
        vscode-wayland = a: pkgs.symlinkJoin {
          name = "code";
          paths = [ (vscode-fhsWithPackages a) ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/code \
              --set-default NIXOS_OZONE_WL 1
          '';
        };
      in
      vscode-wayland(ps: with ps; [
        rnix-lsp
        bintools
        # jdk17_headless rustup # for Prusti
      ]); # vscodium version can't use synchronization. FHS version works better with internet's extensions
      #userSettings = { # we use synchronization feature instead
      #  "editor.bracketPairColorization.enabled" = true;
      #  "editor.guides.bracketPairs" = "active";
      #  "editor.fontFamily" =  "'FiraCode Nerd Font Mono', 'Droid Sans Mono', 'monospace', monospace, 'Droid Sans Fallback'";
      #  "terminal.integrated.fontFamily" = "'FiraCode Nerd Font Mono'";
      #  "rust-analyzer.server.path" = "/etc/profiles/per-user/paulg/bin/rust-analyzer";
      #};
      #extensions = with pkgs.vscode-extensions; [
      #  #matklad.rust-analyzer # already defined in rust module
      #  tamasfe.even-better-toml
      #  serayuzgur.crates
      #  vadimcn.vscode-lldb
      #  #jscearcy.rust-doc-viewer
      #  usernamehw.errorlens
      #  eamodio.gitlens
      #  #swellaby.vscode-rust-test-adapter
      #  #sidp.strict-whitespace
      #];
    };
    terminator = {
      enable = true;
      config = {};
    };
  };

  fonts.fontconfig.enable = true;
}
