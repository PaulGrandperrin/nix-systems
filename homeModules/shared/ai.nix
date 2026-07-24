{pkgs, inputs, lib, ...}: let 
in {
  imports = [
  ];
  home = {
    packages = with pkgs; [
      unstable.opencode
      unstable.opencode-desktop
      unstable.pi-coding-agent
    ];
  };
}
