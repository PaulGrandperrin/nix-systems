{pkgs, inputs, ...}: let
  
  # flutter 1.13 needs platforms = 33 and build-tools = 30.0.3
  # platform: sdk
  # build-tools: aapt2, apksigner, ...
  # platform-tools: adb, fastboot
  # cmdline-tools: avdmanager, sdkmanager
  # tools: deprecated, replaced by cmdline-tools

  #androidSdk = pkgs.androidenv.composeAndroidPackages {
  #  platformVersions = [ "33" ];
  #  buildToolsVersions = ["30.0.3"];
  #  #platformToolsVersion = "33.0.3";
  #  #abiVersions = [ "x86_64" ];
  #}.androidsdk;
  #ANDROID_HOME = "${androidSdk}/libexec/android-sdk/";

  androidSdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (sdkPkgs: with sdkPkgs; [
    platforms-android-33
    build-tools-30-0-3
    cmdline-tools-latest
    platform-tools
    #emulator
  ]);
  ANDROID_HOME = "${androidSdk}/share/android-sdk";

in {
  packages = with pkgs; [
    androidSdk
    flutter

    androidStudioPackages.stable
    #google-chrome

    ## flutter linux deps:
    #cmake
    #ninja
    #pkg-config
  ];

  languages.java = {
    enable = true;
    #gradle.enable = true;
    jdk.package = pkgs.jdk17;
  };

  env = {
    inherit ANDROID_HOME;
    ANDROID_SDK_ROOT = ANDROID_HOME; # deprecated
    #CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";

    #GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/33.0.2/aapt2"; # old aapt2 from 30.0.3 might be buggy?
    #GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=${pkgs.aapt}/bin/aapt2"; # old aapt2 from 30.0.3 might be buggy?
  };
}
