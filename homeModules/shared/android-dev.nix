{pkgs, inputs, lib, config, ...}: {
  imports = [
     inputs.android-nixpkgs.hmModule
  ];
  config = lib.mkIf (config.home.username != "root") {
    android-sdk = {
      enable = true;
      packages = sdk: with sdk; [
          cmdline-tools-latest
          build-tools-34-0-0
          emulator
          ndk-bundle
          platform-tools # conflict with mke2fs
          platforms-android-34
          #tools # breaks sdkmanager
      ];
    };
    home = {
      packages = with pkgs; [
        android-studio
        openjdk19_headless
        flutter
        #cmake
        #ninja
        #pkg-config
      ];
      #sessionVariables = {
      #  #ANDROID_HOME = 
      #};
    };
  };
}
