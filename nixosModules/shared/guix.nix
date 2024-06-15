{...}: {
  services.guix = {
    enable = true;
    gc = {
      enable = true;
      extraArgs = [];
      dates = "5:00:00";
    };
  };
  home-manager.users = {
    root.home.sessionVariables.GUIX_PROFILE = "/root/.guix-profile";
    paulg.home.sessionVariables.GUIX_PROFILE = "/home/paulg/.guix-profile";
  };
}
