{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      firefox
      terminator
    ];

    sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };
  };

}
