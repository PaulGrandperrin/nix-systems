{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      firefox
      terminator
    ];
    sessionVariables = {
    };

  };

  systemd.user.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

}
