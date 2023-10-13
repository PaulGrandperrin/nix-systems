{pkgs, inputs, lib, config, ...}: lib.mkIf (config.home.username != "root") {
  home = {
    packages = with pkgs; [
      wineWowPackages.waylandFull
      winetricks
    ];
  };
}
