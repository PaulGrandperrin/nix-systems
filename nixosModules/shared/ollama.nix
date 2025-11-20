{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.paulg.ollama;
in {
  options.paulg.ollama = {
    enable = mkEnableOption "ollama";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      #acceleration = "vulkan"; # waiting for https://github.com/NixOS/nixpkgs/pull/463430
    };

    services.nextjs-ollama-llm-ui = {
      enable = true;
      hostname = "${config.networking.hostName}.wg";
    };

    # force vulkan until PR is merged
    services.ollama.package = pkgs.unstable.ollama-vulkan;
    systemd.services.ollama.environment.OLLAMA_VULKAN = "1";
    systemd.services.ollama.serviceConfig.ExecStart = lib.mkForce "${lib.getExe pkgs.unstable.ollama-vulkan} serve";
    environment.systemPackages = [ (lib.hiPrio pkgs.unstable.ollama-vulkan) ];
  };
}


