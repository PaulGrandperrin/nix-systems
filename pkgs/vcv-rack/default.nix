{ gcc11Stdenv
, lib
, makeWrapper
, fetchzip
, fetchFromGitHub
, fetchFromBitbucket
, pkg-config
, alsa-lib
, curl
, ghc_filesystem
, glew
, glfw
, gtk3-x11
, jansson
, jq
, libarchive
, libjack2
, libpulseaudio
, libXext
, libXi
, rtaudio
, rtmidi
, speex
, libsamplerate
, zstd
, wrapGAppsHook
}:

let
  # The package repo vendors some of the package dependencies as submodules.
  # Unfortunately, they are not pinned, so we have no guarantee that they
  # will be stable, and therefore, we can't use them directly. Instead
  # we'll have to fetch them separately ourselves.
  pffft-source = fetchFromBitbucket {
    owner = "jpommier";
    repo = "pffft";
    rev = "988259a41d1522047a9420e6265a6ba8289c1654";
    sha256 = "Oq5N02UNXsbhcPUfjMtD0cgqAZsGx9ke9A+ArrenzGE=";
  };
  fuzzysearchdatabase-source = fetchFromBitbucket {
    owner = "j_norberg";
    repo = "fuzzysearchdatabase";
    rev = "fe62479811e503ef3c091f5a859d27bfcf0a44da";
    sha256 = "zgeUzuuInHPeveBIjlivRGIz+NSb7cW/9hMndxm6qOA=";
  };
  nanovg-source = fetchFromGitHub {
    owner = "VCVRack";
    repo = "nanovg";
    rev = "0bebdb314aff9cfa28fde4744bcb037a2b3fd756";
    sha256 = "HmQhCE/zIKc3f+Zld229s5i5MWzRrBMF9gYrn8JVQzg=";
  };
  nanosvg-source = fetchFromGitHub {
    owner = "memononen";
    repo = "nanosvg";
    rev = "ccdb1995134d340a93fb20e3a3d323ccb3838dd0";
    sha256 = "ymziU0NgGqxPOKHwGm0QyEdK/8jL/QYk5UdIQ3Tn8jw=";
  };
  osdialog-source = fetchFromGitHub {
    owner = "AndrewBelt";
    repo = "osdialog";
    rev = "e5faf7ea0fce3104bf0c8f2c0e8a5a2e454ed42f";
    sha256 = "5b+OjaoP5hRs53UED0Z5ro2HD/75K5NyzKQiO5pNBEU=";
  };
  oui-blendish-source = fetchFromGitHub {
    owner = "AndrewBelt";
    repo = "oui-blendish";
    rev = "2fc6405883f8451944ed080547d073c8f9f31898";
    sha256 = "/QZFZuI5kSsEvSfMJlcqB1HiZ9Vcf3vqLqWIMEgxQK8=";
  };
  fundamental-source = fetchFromGitHub {
    owner = "VCVRack";
    repo = "Fundamental";
    rev = "533397cdcad5c6401ebd3937d6c1663de2473627"; # tip of branch v2
    sha256 = "QnwOgrYxiCa/7t/u6F63Ks8C9E8k6T+hia4JZFhp1LI=";
  };
in
# gcc11 is necessary because many vcv plugins are already built with it
  # If using an older gcc for Rack, you get
  # undefined symbol: _ZSt28__throw_bad_array_new_lengthv
  # for those plugins which were built with v11
with lib; gcc11Stdenv.mkDerivation rec {
  pname = "VCV-Rack";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "VCVRack";
    repo = "Rack";
    rev = "v${version}";
    sha256 = "cK4dZgTx3Gq/UKfnCycLp7Y8fbrgRTHI9Ef19nNWd0o=";
  };

  patches = [
    ./rack-minimize-vendoring.patch
  ];

  prePatch = ''
    # As we can't use `make dep` to set up the dependencies (as explained
    # above), we do it here manually
    mkdir -p dep/include

    cp -r ${pffft-source}/* dep/pffft
    cp -r ${fuzzysearchdatabase-source}/* dep/fuzzysearchdatabase
    cp -r ${nanovg-source}/* dep/nanovg
    cp -r ${nanosvg-source}/* dep/nanosvg
    cp -r ${osdialog-source}/* dep/osdialog
    cp -r ${oui-blendish-source}/* dep/oui-blendish

    cp dep/pffft/*.h dep/include
    cp dep/fuzzysearchdatabase/src/*.hpp dep/include
    cp dep/nanosvg/**/*.h dep/include
    cp dep/nanovg/src/*.h dep/include
    cp dep/osdialog/*.h dep/include
    cp dep/oui-blendish/*.h dep/include

    # Build and dist the Fundamental plugins
    cp -r ${fundamental-source} plugins/Fundamental/
    chmod -R +rw plugins/Fundamental # will be used as build dir
    substituteInPlace plugin.mk --replace ":= all" ":= dist"
  '';

  enableParallelBuilding = true;

  nativeBuildInputs = [ makeWrapper pkg-config wrapGAppsHook ];
  buildInputs = [ alsa-lib curl ghc_filesystem glew glfw gtk3-x11 jansson jq libarchive libjack2 libpulseaudio libsamplerate rtaudio rtmidi speex zstd ];

  makeFlags = [ "all" "plugins" ];

  installPhase = ''
    install -D -m755 -t $out/bin Rack
    install -D -m755 -t $out/lib libRack.so

    mkdir -p $out/share/vcv-rack
    cp -r res cacert.pem Core.json template.vcv LICENSE-GPLv3.txt $out/share/vcv-rack
    cp -r plugins/Fundamental/dist/Fundamental-*.vcvplugin $out/share/vcv-rack/Fundamental.vcvplugin

    # Override the default global resource file directory
    wrapProgram $out/bin/Rack --add-flags "-s $out/share/vcv-rack"
  '';

  meta = with lib; {
    description = "Open-source virtual modular synthesizer";
    homepage = "https://vcvrack.com/";
    # The source is BSD-3 licensed, some of the art is CC-BY-NC 4.0 or under a
    # no-derivatives clause
    license = with licenses; [ bsd3 cc-by-nc-40 unfreeRedistributable ];
    maintainers = with maintainers; [ moredread nathyong jpotier ];
    platforms = platforms.linux;
  };
}
