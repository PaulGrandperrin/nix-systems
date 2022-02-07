{pkgs, ...}: {
  home = {
    packages = with pkgs; [
    ]
    ++ (if system == "x86_64-linux" then [ # linux only
      parted
      iftop
    ] else []);
  };
}
