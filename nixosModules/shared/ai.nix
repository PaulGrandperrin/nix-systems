{ config, pkgs, lib, inputs, ... }:
with lib;
let
  cfg = config.paulg.ai;
in {
  imports = [];

  options.paulg.ai = {
    enable = mkEnableOption "ai";
  };

  config = mkIf cfg.enable {
    home-manager.users.paulg.home.packages = with pkgs; [
      unstable.python314Packages.huggingface-hub
      unstable.llama-cpp-vulkan
      unstable.stable-diffusion-cpp-rocm
    ];

    services.open-webui = {
      enable = true;
      package = pkgs.unstable.open-webui;
    };

    environment.systemPackages = with pkgs; [
      inputs.llama-cpp.packages.${stdenv.hostPlatform.system}.vulkan
    ];

    sops.secrets.HF_TOKEN = {
      mode = "0440";
      owner = "root";
      group = "wheel";
      sopsFile = ../../secrets/other.yaml;
    };

    programs.fish.loginShellInit = lib.mkAfter ''
      test -f ${config.sops.secrets.HF_TOKEN.path} && set -gx HF_TOKEN (cat ${config.sops.secrets.HF_TOKEN.path})
    '';

  };

}



