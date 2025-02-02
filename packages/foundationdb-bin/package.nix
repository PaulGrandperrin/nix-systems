{
  lib,

  fetchurl,
  autoPatchelfHook,
  dpkg,
  stdenvNoCC,
  xorg,

  xz,
  zlib,

  version ? "7.3.57",
}: let
  meta = with lib; {
    description = "Open source, distributed, transactional key-value store";
    homepage    = "https://www.foundationdb.org";
    license     = licenses.asl20;
    platforms   = [ "x86_64-linux" "aarch64-linux" ];
  };

  versions = {
    "7.3.59" = { # pre-release
      x86_64 = {
        clients = "sha256-qGRMZrGK9z+ATpuHF64+hfbUCke+0130lIhxUpwOvtY=";
        server = "sha256-HKD7oJLb1bZy4KJPprWxItcifdfqPdvhnYn50LNMZuU=";
      };
      arm64 = {
        clients = "sha256-jVIGk5exXukqmJd03ltLmo4SkuBDhiDBDTs5VzydJbw=";
        server = "sha256-jZXW06iP0EorCxYg8wIsGNETXnzjXk4Iurgqp9dDvmU=";
      };
    };
    "7.3.57" = { # latest
      x86_64 = {
        clients = "sha256-v1ssLbMb/0J2gl3zfSka7YBDF3a6Mz+FMKD3xa7sAR0=";
        server = "sha256-ys7WnJOdqwjJtNx2N/NrplIvPfpTUHFlW7uFkCz5Ra0=";
      };
    };
  };

  arch = stdenvNoCC.hostPlatform.linuxArch;
  arch_deb = {
    "x86_64" = "amd64";
    "arm64" = "aarch64";
  }.${arch};
  
  mkFoundationdbBin = artifactName: version: stdenvNoCC.mkDerivation {
    pname = "foundationdb-bin-${artifactName}";
    inherit version;
    src = fetchurl {
      url = "https://github.com/apple/foundationdb/releases/download/${version}/foundationdb-${artifactName}_${version}-1_${arch_deb}.deb";
      hash = versions.${version}.${arch}.${artifactName};
    };

    dontBuild = true;
    nativeBuildInputs = [ dpkg autoPatchelfHook ];
    buildInputs = [
      xz
      zlib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,libexec}
      find usr/{bin,sbin,lib/foundationdb}/ -maxdepth 1 -type f -executable -print -exec mv '{}' $out/bin/ \; || true
      find usr/lib/foundationdb/backup_agent/ -maxdepth 1 -type f -executable -print -exec mv '{}' $out/libexec/ \; || true

      mkdir -p $dev/lib
      find usr/include -maxdepth 0 -type d -print -exec mv '{}' $dev/ \; || true
      find usr/lib/{cmake,pkgconfig} -maxdepth 0 -type d -print -exec mv '{}' $dev/lib/ \; || true

      mkdir -p $lib/lib
      find usr/lib/ -maxdepth 1 -type f -name "*.so" -print -exec mv '{}' $lib/lib/ \; || true

      runHook postInstall
    '';

    outputs = [ "out" "dev" "lib" ];

    inherit meta;
  };

  foundationdb-bin = stdenvNoCC.mkDerivation rec {
    pname = "foundationdb-bin";
    inherit version;
    outputs = [ "out" "dev" "lib" ];

    buildCommand = ''
      mkdir -p $out
      for i in ${(mkFoundationdbBin "clients" version).out} ${(mkFoundationdbBin "server" version).out}; do
        ${xorg.lndir}/bin/lndir -silent $i $out
      done

      mkdir -p $dev
      for i in ${(mkFoundationdbBin "clients" version).dev} ${(mkFoundationdbBin "server" version).dev}; do
        ${xorg.lndir}/bin/lndir -silent $i $dev
      done

      mkdir -p $lib
      for i in ${(mkFoundationdbBin "clients" version).lib} ${(mkFoundationdbBin "server" version).lib}; do
        ${xorg.lndir}/bin/lndir -silent $i $lib
      done
    '';

    inherit meta;
  };
in
  foundationdb-bin
