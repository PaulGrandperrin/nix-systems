{pkgs, inputs, lib, config, ...}: lib.mkIf (config.home.username != "root") {
  home = {
    packages = with pkgs; [

      (let my-kodi = 
        kodi-wayland.withPackages (kodiPkgs: with kodiPkgs; [
          #youtube
          libretro
          libretro-snes9x
          #osmc-skin
          arteplussept
          steam-library
          steam-launcher
        ]
      ); in 
        buildFHSUserEnvBubblewrap {
          name = "kodi";
          targetPkgs = pkgs: (with pkgs; [
          ]);
          runScript = "${my-kodi}/bin/kodi";
        }
      )
    ];
  };
}

