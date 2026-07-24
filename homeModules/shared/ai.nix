{pkgs, inputs, lib, ...}: let 
in {
  imports = [
  ];
  home = {
    packages = with pkgs; [
      opencode
      opencode-desktop
    ];
  };
}
