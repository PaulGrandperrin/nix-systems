{pkgs, inputs, lib, config, ...}: lib.mkIf (config.home.username != "root") {
  home = {
    packages = with pkgs; [
      wineWow64Packages.waylandFull
      winetricks
    ];
  };
}
