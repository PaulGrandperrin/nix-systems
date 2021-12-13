{pkgs, ...}: {
  nix.package = pkgs.nix_2_4;
  nix.extraOptions = "experimental-features = nix-command flakes";

  services.nix-daemon.enable = true;
  environment.systemPackages = [];
  system.stateVersion = 4;

  programs = {
    fish.enable = true;
  };

  environment.shells = [pkgs.fish];
}
