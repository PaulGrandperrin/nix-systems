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
  };
}



