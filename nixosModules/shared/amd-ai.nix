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
      enableNPU = true;         # default; set false for GPU-only hosts (see "Other hardware")
      enableFastFlowLM = true;  # LLM inference on NPU (requires enableNPU)
      enableLemonade = true;    # OpenAI-compatible API server
      enableROCm = true;        # ROCm GPU backends (llamacpp + sd-cpp)
      enableVulkan = true;      # Vulkan GPU backends (llamacpp + whispercpp)
      enableImageGen = true;    # default true; set false to drop sd-cpp from closure
      lemonade.user = "paulg";
    };

    users.users.paulg.extraGroups = ["video" "render"];
  };
}


