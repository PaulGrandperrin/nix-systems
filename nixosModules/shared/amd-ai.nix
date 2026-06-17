{ config, pkgs, lib, inputs, ... }:
with lib;
let
  cfg = config.paulg.amd-ai;
in {
  imports = [inputs.nix-amd-ai.nixosModules.default];

  options.paulg.amd-ai = {
    enable = mkEnableOption "amd-ai";
  };

  config = mkIf cfg.enable {
    hardware.amd-npu = {
      enable = true;
      enableNPU = true;
      enableFastFlowLM = true;
      enableLemonade = true;
      enableROCm = true;
      enableVulkan = true;
      enableImageGen = true;

      lemonade.user = "paulg";
    };

    users.users.paulg.extraGroups = ["video" "render"];
  };
}


