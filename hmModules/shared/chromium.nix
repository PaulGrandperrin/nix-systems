args @ {pkgs, inputs, lib, config, ...}: lib.mkIf (config.home.username != "root") { 
  programs = {
    chromium = {
      enable = true;
      package = if (args ? nixosConfig) then pkgs.chromium else pkgs.emptyDirectory;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "fihnjjcciajhdojfnbdddfaoknhalnja"; } # I don't care about cookies
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      ];
    };
  };

}
