{config, lib, pkgs, inputs, ...}: {
  nixpkgs.hostPlatform = "x86_64-linux";
  system-manager.allowAnyDistro = true;

  environment = {
    etc = {
      "foo.conf".text = ''
        launch_the_rockets = true
      '';
    };
    systemPackages = [
      inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.system-manager
    ];
  };
}
