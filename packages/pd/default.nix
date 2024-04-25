{ 
  rev ? "b4f7f467c05bc2e446fff46c6d7fc195d0283f55",
  hash ? "sha256-inig6Twi3u3Ay0R/cd1O31eAYDl/NJQO+hemFFkiHT0=",

  lib,

  stdenv_32bit,
  fetchFromGitHub,
  fetchpatch,

  pkgsi686Linux, # SDL2 and zlib

  pkg-config,
  python3,
}: let
  shortrev = builtins.substring 0 9 rev;
in stdenv_32bit.mkDerivation rec {
    pname = "pd";
    version = shortrev;

    meta = with lib; {
      homepage = "https://github.com/fgsfdsfgs/perfect_dark";
      description = "A PC port of Perfect Dark based on the decompilation of the Nintendo 64 game";
      mainProgram = "pd";
      platforms = [ "i686-linux" "x86_64-linux" ];
      maintainers = with maintainers; [  ]; # TODO
      license = with licenses; [
        # pd, khrplatform.h, port/fast3d
        mit
        # tools/mkrom/gzip
        gpl3Plus
      ];
    };

    src = fetchFromGitHub {
      owner = "fgsfdsfgs";
      repo = "perfect_dark";
      inherit rev hash;
    };

    patches = [
      (fetchpatch { # fix parallel compilation
        url = "https://github.com/fgsfdsfgs/perfect_dark/commit/73dc52cfd6cc3032595a9e0accbb901af53d2485.patch";
        hash = "sha256-NLeWJ0WQu70mpwEhqtz35D3V/36LUdNugrzFz9I28f4=";
      })
    ];

    buildInputs = with pkgsi686Linux; [
      SDL2
      zlib
    ];

    nativeBuildInputs = [
      pkg-config # TODO try remove
      python3
    ];

    # the project uses git to retrieve version informations but our fetcher deletes the .git
    # so we replace the commands with the correct data directly
    postPatch = ''
      sed -i 's/git rev-parse --short HEAD/echo ${shortrev}/' Makefile.port
      sed -i 's/git rev-parse --abbrev-ref HEAD/echo port/' Makefile.port
    '';

    enableParallelBuilding = true;

    hardeningDisable = [ "format" ]; # otherwise fails to build

    makeFlags = [
      "TARGET_PLATFORM=i686-linux" # the project is 32-bit only for now
    ];

    makefile = "Makefile.port";

    preBuild = ''
      patchShebangs .
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mv build/ntsc-final-port/pd.exe $out/bin/pd

      runHook postInstall
    '';
  }
