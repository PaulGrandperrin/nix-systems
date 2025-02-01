{
  lib,

  fetchurl,
  autoPatchelfHook,
  dpkg,
  stdenvNoCC,
  xorg,

  xz,
  zlib,
}: let
  meta = with lib; {
    description = "Open source, distributed, transactional key-value store";
    homepage    = "https://www.foundationdb.org";
    license     = licenses.asl20;
    platforms   = [ "x86_64-linux" ];
  };
  
  foundationdb-clients-bin = stdenvNoCC.mkDerivation rec {
    pname = "foundationdb-clients-bin";
    version = "7.3.57";
    src = fetchurl {
      url = "https://github.com/apple/foundationdb/releases/download/${version}/foundationdb-clients_${version}-1_amd64.deb";
      hash = "sha256-v1ssLbMb/0J2gl3zfSka7YBDF3a6Mz+FMKD3xa7sAR0=";
    };

    dontBuild = true;
    nativeBuildInputs = [ dpkg autoPatchelfHook ];
    buildInputs = [
      xz
      zlib
    ];

    installPhase = ''
      runHook preInstall

      ls -R
      mkdir -p $out/{bin,libexec}
      mv usr/{bin,sbin}/* $out/bin/
      mv usr/lib/foundationdb/backup_agent/* $out/libexec/

      mkdir -p $dev/lib
      mv usr/include $dev/
      mv usr/lib/cmake $dev/lib/
      mv usr/lib/pkgconfig $dev/lib/

      mkdir -p $lib/lib
      mv usr/lib/*.so $lib/lib/

      runHook postInstall
    '';

    outputs = [ "out" "dev" "lib" ];

    inherit meta;
  };

  foundationdb-server-bin = stdenvNoCC.mkDerivation rec {
    pname = "foundationdb-server-bin";
    version = "7.3.57";
    src = fetchurl {
      url = "https://github.com/apple/foundationdb/releases/download/${version}/foundationdb-server_${version}-1_amd64.deb";
      hash = "sha256-ys7WnJOdqwjJtNx2N/NrplIvPfpTUHFlW7uFkCz5Ra0=";
    };

    dontBuild = true;
    nativeBuildInputs = [ dpkg autoPatchelfHook ];
    buildInputs = [
      xz
      zlib
    ];

    installPhase = ''
      runHook preInstall

      ls -R
      mkdir -p $out/bin
      mv usr/{bin,sbin}/* $out/bin/
      mv usr/lib/foundationdb/fdbmonitor $out/bin/

      runHook postInstall
    '';

    inherit meta;
  };

  foundationdb-bin = stdenvNoCC.mkDerivation {
    pname = "foundationdb-bin";
    version = "7.3.57";
    outputs = [ "out" "dev" "lib" ];

    buildCommand = ''
      mkdir -p $out
      for i in ${foundationdb-clients-bin} ${foundationdb-server-bin}; do
        ${xorg.lndir}/bin/lndir -silent $i $out
      done

      mkdir -p $dev
      for i in ${foundationdb-clients-bin.dev}; do
        ${xorg.lndir}/bin/lndir -silent $i $dev
      done

      mkdir -p $lib
      for i in ${foundationdb-clients-bin.lib}; do
        ${xorg.lndir}/bin/lndir -silent $i $lib
      done
    '';

    inherit meta;
  };
in
  foundationdb-bin
