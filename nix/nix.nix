# nix.settings in NixOS and home-manager
# can be impurely extended in /etc/nix/nix.conf or ~/.config/nix/nix.conf
# can be extended in plain text with nix.extraOptions
{
  experimental-features = "nix-command flakes repl-flake";
  auto-optimise-store = true; # maybe causes build failures
  allowed-users = [ "@wheel" "nix-serve" ];
  #trusted-users = ["@wheel"];

  extra-substituters = [
    #"http://nixos-nas.wg:5000" # breaks everything when host is down: https://github.com/NixOS/nix/issues/6901
    "https://nix-community.cachix.org"
    "https://cache.nixos.org"
    "https://devenv.cachix.org"
  ];
  extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nas.grandperrin.fr:QwhwNrClkzxCvdA0z3idUyl76Lmho6JTJLWplKtC2ig="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];
}
