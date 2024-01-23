{
  symlinkJoin,
  callPackage,
  gnome,
  wrapFirefox,
  makeWrapper,
  path,
  unstable, # ? {inherit path;},
  ...
}: let
  # build firefox-bin version from nixos-unstable but with current dependencies
  path = unstable.path;
  firefox-bin-unwrapped = callPackage ( # taken from pkgs/top-level/all-packages.nix
    path + "/pkgs/applications/networking/browsers/firefox-bin"
  ) {
    inherit (gnome) adwaita-icon-theme;
    channel = "release";
    #generated = import ( path + "/pkgs/applications/networking/browsers/firefox-bin/release_sources.nix");
    generated = import ./release_sources.nix;
    autoPatchelfHook = unstable.autoPatchelfHook;
  };
  firefox-bin = wrapFirefox firefox-bin-unwrapped { # taken from pkgs/top-level/all-packages.nix
    applicationName = "firefox";
    pname = "firefox-bin";
    desktopName = "Firefox";
  };
in symlinkJoin {
  name = "firefox-bin";
  paths = [ firefox-bin ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/firefox \
      --set-default "MOZ_ENABLE_WAYLAND" "1" \
      --set-default "MOZ_USE_XINPUT2" "1"
  '';
}



