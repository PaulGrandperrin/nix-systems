{config, pkgs, inputs, ...}: let
  
  # flutter 1.13 needs platforms = 33 and build-tools = 30.0.3
  # platform: sdk
  # build-tools: aapt2, apksigner, ...
  # platform-tools: adb, fastboot
  # cmdline-tools: avdmanager, sdkmanager
  # tools: deprecated, replaced by cmdline-tools

  #androidSdk = (pkgs.androidenv.composeAndroidPackages {
  #  platformVersions = [ "33" ];
  #  buildToolsVersions = ["30.0.3"];
  #  #platformToolsVersion = "33.0.3";
  #  #abiVersions = [ "x86_64" ];
  #}).androidsdk;
  #androidSdkSubPath="lib-exec/android-sdk";

  androidSdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (sdkPkgs: with sdkPkgs; [
    platforms-android-33
    build-tools-30-0-3
    cmdline-tools-latest
    platform-tools
    #emulator
  ]);
  androidSdkSubPath="share/android-sdk";

in {
  packages = with pkgs; [
    androidSdk
    flutter

    androidStudioPackages.stable
    #google-chrome
  ];

  languages.java = {
    enable = true; # also sets JAVA_HOME for flutter cmdline
    #gradle.enable = true;
    jdk.package = pkgs.jdk17;
  };

  env = rec {
    ANDROID_HOME = "${androidSdk}/${androidSdkSubPath}"; # for flutter cmdline
    ANDROID_SDK_ROOT = ANDROID_HOME; # deprecated
    #CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
  };

  enterShell = ''
    echo
    echo "Stable SDK paths (for android-studio which doesn't use env vars):"
    echo "android: $(pwd)/.devenv/profile/${androidSdkSubPath}"
    echo "flutter: $(pwd)/.devenv/profile"
    echo "java:    $(pwd)/.devenv/profile/lib/openjdk"
    echo
  
    ## also add gcroots?
    #ln -s ${androidSdk} .android-sdk
    #ln -s ${pkgs.flutter} .flutter-sdk
    #ln -s ${config.languages.java.jdk.package} .java-sdk
  '';
}
