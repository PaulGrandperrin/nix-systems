{
  writeShellApplication
}:
writeShellApplication {
  name = "vim-distro-format";
  text = ''
    test $# -eq 0 && echo "Missing application name" && exit 1 
    set -x
    rm -rf "''${XDG_CONFIG_HOME:?}/$1" "''${XDG_CACHE_HOME:?}/$1" "''${XDG_DATA_HOME:?}/$1" "''${XDG_STATE_HOME:?}/$1"
  '';
}

