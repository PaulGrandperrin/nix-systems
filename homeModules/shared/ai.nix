{pkgs, inputs, lib, ...}: let 
in {
  imports = [
  ];
  home = {
    packages = with pkgs.unstable; [
      opencode
      opencode-desktop
      pi-coding-agent
      nodejs
    ];
  };
}
