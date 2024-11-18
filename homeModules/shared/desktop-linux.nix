{pkgs, inputs, lib, config, ...}: lib.mkIf (config.home.username != "root") {
  home = {
    packages = with pkgs; [

      # nix run --impure --expr '(builtins.getFlake "n").legacyPackages.x86_64-linux.blender.override {cudaSupport = true;}'

      qemu_kvm
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
      element-desktop-wayland
      (nerdfonts.override { fonts = [ "FiraCode" ]; })
      deluge
      rawtherapee
      libreoffice
      helvum
      unstable.popcorntime
      swappy
      speechd # for spd-say
      unstable.zed-editor
      unstable.lapce

      #gnome.gnome-boxes libvirt # doesn't work, but flatpak version does

      # I want protonvpn from unstable but I don't want to pull its dependencies from unstable
      #(callPackage (inputs.nixos-unstable.outPath + "/pkgs/applications/networking/protonvpn-gui") {
      #  python3Packages = ( python3Packages // {protonvpn-nm-lib = python3Packages.callPackage (inputs.nixos-unstable.outPath + "/pkgs/development/python-modules/protonvpn-nm-lib") {};});
      #})
    ];
    sessionVariables = { # only works for interactive shells
    };

  };

  # nixgl or hardware.graphics.setLdLibraryPath = true;

  #xdg.configFile."wireplumber/default-profile".text = ''
  #  [default-profile]
  #  bluez_card.60_AB_D2_23_56_13=a2dp-sink-sbc_xq
  #'';


  #xdg.configFile = {
  #  "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
  #    bluez_monitor.properties = {
  #      ["bluez5.enable-sbc-xq"] = true,
  #      ["bluez5.enable-msbc"] = true,
  #      ["bluez5.enable-hw-volume"] = true,
  #      ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]",
  #    }
  #  '';
  #  "wireplumber/bluetooth.lua.d/51-bluez-bose700-sbc_xq.lua".text = ''
  #    rule = {
  #      matches = {
  #        {
  #          { "node.name", "equals", "bluez_output.60_AB_D2_23_56_13.a2dp-sink" },
  #        },
  #      },                                                                                                                                                                                   
  #      apply_properties = {
  #        ["api.bluez5.codec"] = "sbc_xq", -- force SBC_XQ or else AAC is choosen
  #      },
  #    }
  #    table.insert(bluez_monitor.rules,rule)
  #  '';
  #};

  home.activation.copySshAuthorizedKeys = lib.mkForce ""; # don't trust servers to connect to desktops

  systemd.user.sessionVariables = {
  };

  # see also: https://github.com/rclone/rclone/wiki/Systemd-rclone-mount
  systemd.user.mounts."home-${config.home.username}-Google\\x20Drive" = {
    Unit = {
      Description = "Mount Google Drive with rclone on fuse";
    };
    Install.WantedBy = [ "default.target" ];
    Mount = {
      ExecSearchPath = "${pkgs.rclone}/bin/:/run/wrappers/bin/"; # the wrappers are needed for fusermount3 with suid
      What = "gdrive:";
      Where = "/home/${config.home.username}/Google Drive";
      Type = "fuse.rclonefs";
      Options = "_netdev,args2env,vfs-cache-mode=full,dir-cache-time=5000h,poll-interval=10s,vfs-cache-max-age=90d,vfs-cache-max-size=5G,transfers=32,checkers=32"; # allow-non-empty
    };
  };

  services = {
    #flameshot.enable = true; #TODO
  };

  programs = {
    foot.enable = true;
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
      #vscode-wayland(ps: with ps; [ # buggy
      vscode-fhsWithPackages(ps: with ps; [
        nixd
        nixpkgs-fmt
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

