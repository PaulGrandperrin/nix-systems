{
  lib,

  neovim,
  symlinkJoin,
  makeWrapper,
  git,

  ripgrep,
  fd,
  lazygit,
  gcc,

  name,
  conf-repo-url
}: let
  nvim-full = neovim.override {withNodeJs = true;};
in symlinkJoin {
  inherit name;
  paths = [ nvim-full ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    mv $out/bin/nvim $out/bin/${name}
    wrapProgram $out/bin/${name} \
      --inherit-argv0 \
      --set "NVIM_APPNAME" "${name}" \
      --run 'test ! -d "$XDG_CONFIG_HOME/$NVIM_APPNAME" && mkdir -p "$XDG_CONFIG_HOME/$NVIM_APPNAME" && ${git}/bin/git clone --depth 1 ${conf-repo-url} "$XDG_CONFIG_HOME/$NVIM_APPNAME"' \
      --suffix "PATH" ":" "${lib.makeBinPath [ ripgrep fd git lazygit gcc ]}"
  '';
}

