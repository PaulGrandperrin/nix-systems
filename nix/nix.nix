# nix.settings in NixOS and home-manager
# can be impurely extended in /etc/nix/nix.conf or ~/.config/nix/nix.conf
# can be extended in plain text with nix.extraOptions
rec {
  experimental-features = "nix-command flakes";
  auto-optimise-store = true; # maybe causes build failures
  allowed-users = [ "@wheel" "nix-serve" ];
  #trusted-users = ["@wheel"]; # only do it on desktop machines

  substituters = [
    "http://nixos-nas.wg:5000" # breaks everything when host is down: https://github.com/NixOS/nix/issues/6901
    "https://nix-community.cachix.org"
    "https://devenv.cachix.org"
    "https://nix-amd-ai.cachix.org"
  ];
  trusted-substituters = substituters; # my system subtituters can be used by untrusted users
  trusted-public-keys = [
    "nas.grandperrin.fr:QwhwNrClkzxCvdA0z3idUyl76Lmho6JTJLWplKtC2ig="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    "nix-amd-ai.cachix.org-1:F4OU4vw/lV2oiG6SBHZ+nqjl4EFJuqI4X9A7pvaBmhQ="
  ];
}
