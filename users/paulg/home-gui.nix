{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      firefox
      terminator
    ];
  };
}
